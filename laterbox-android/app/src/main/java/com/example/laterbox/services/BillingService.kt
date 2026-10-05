package com.example.laterbox.services

import android.app.Activity
import com.android.billingclient.api.*
import kotlinx.coroutines.suspendCancellableCoroutine
import org.json.JSONObject
import kotlin.coroutines.resume
import kotlin.coroutines.resumeWithException

class BillingService(private val activity: Activity, private val onPurchases: (List<Purchase>) -> Unit) : AutoCloseable {
    private val client = BillingClient.newBuilder(activity).setListener { result, purchases -> if (result.responseCode == BillingClient.BillingResponseCode.OK) onPurchases(purchases.orEmpty()) }
        .enablePendingPurchases(PendingPurchasesParams.newBuilder().enableOneTimeProducts().build()).enableAutoServiceReconnection().build()
    suspend fun connect() = suspendCancellableCoroutine<Unit> { continuation ->
        client.startConnection(object : BillingClientStateListener {
            override fun onBillingSetupFinished(result: BillingResult) { if (!continuation.isActive) return; if (result.responseCode == BillingClient.BillingResponseCode.OK) continuation.resume(Unit) else continuation.resumeWithException(IllegalStateException("Google Play billing is unavailable (${result.responseCode})")) }
            override fun onBillingServiceDisconnected() {}
        })
    }
    suspend fun products(): List<ProductDetails> = suspendCancellableCoroutine { continuation ->
        val products = listOf("com.laterbox.pro.monthly", "com.laterbox.pro.annual").map { QueryProductDetailsParams.Product.newBuilder().setProductId(it).setProductType(BillingClient.ProductType.SUBS).build() }
        client.queryProductDetailsAsync(QueryProductDetailsParams.newBuilder().setProductList(products).build()) { result, response ->
            if (continuation.isActive) { if (result.responseCode == BillingClient.BillingResponseCode.OK) continuation.resume(response.productDetailsList) else continuation.resumeWithException(IllegalStateException("Unable to load plans")) }
        }
    }
    suspend fun restore(): List<Purchase> = suspendCancellableCoroutine { continuation ->
        client.queryPurchasesAsync(QueryPurchasesParams.newBuilder().setProductType(BillingClient.ProductType.SUBS).build()) { result, purchases ->
            if (continuation.isActive) { if (result.responseCode == BillingClient.BillingResponseCode.OK) continuation.resume(purchases) else continuation.resumeWithException(IllegalStateException("Unable to restore purchases")) }
        }
    }
    fun purchase(product: ProductDetails): BillingResult {
        val user = requireNotNull(AccountService.state.value.userId) { "Sign in before purchasing Pro" }
        val offer = requireNotNull(product.subscriptionOfferDetails?.firstOrNull()) { "No eligible offer" }
        return client.launchBillingFlow(activity, BillingFlowParams.newBuilder().setObfuscatedAccountId(user)
            .setProductDetailsParamsList(listOf(BillingFlowParams.ProductDetailsParams.newBuilder().setProductDetails(product).setOfferToken(offer.offerToken).build())).build())
    }
    suspend fun verify(purchase: Purchase) {
        check(purchase.purchaseState == Purchase.PurchaseState.PURCHASED) { "Purchase is pending. Pro unlocks after payment completes." }
        NativeApi.call("https://laterbox.dev/api/billing/google/verify", "POST", JSONObject().put("purchaseToken", purchase.purchaseToken).put("productId", purchase.products.first()))
        AccountService.refresh()
        check(AccountService.state.value.pro) { "Purchase verified, but Pro access has not refreshed yet. Retry restore." }
    }
    override fun close() { client.endConnection() }
}
