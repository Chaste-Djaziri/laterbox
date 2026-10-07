package com.example.laterbox.ui.screens

import android.content.Intent
import android.net.Uri
import android.webkit.ConsoleMessage
import android.webkit.WebChromeClient
import android.webkit.WebResourceRequest
import android.webkit.WebView
import android.webkit.WebViewClient
import androidx.compose.foundation.layout.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.unit.dp
import androidx.compose.ui.viewinterop.AndroidView
import androidx.lifecycle.Lifecycle
import androidx.lifecycle.LifecycleEventObserver
import androidx.lifecycle.compose.LocalLifecycleOwner
import kotlinx.coroutines.delay
import java.net.URI

internal fun youtubePreviewId(embedUrl: String): String? {
    val uri = runCatching { URI(embedUrl) }.getOrNull() ?: return null
    if (uri.scheme != "https" || uri.host != "www.youtube.com" || !uri.path.orEmpty().startsWith("/embed/")) return null
    return uri.path.substringAfter("/embed/").takeIf { it.matches(Regex("[A-Za-z0-9_-]+")) }
}

internal fun youtubePlayerDocument(videoId: String, origin: String): String {
    require(videoId.matches(Regex("[A-Za-z0-9_-]+")))
    require(origin.matches(Regex("https://[A-Za-z0-9_.-]+")))
    return """
        <!doctype html><html><head><meta name="viewport" content="width=device-width, initial-scale=1">
        <meta name="referrer" content="strict-origin-when-cross-origin">
        <style>html,body{margin:0;height:100%;background:#000}#player{width:100%;height:100%}</style></head>
        <body><div id="player"></div><script>
        function fallback(){var p=document.getElementById('player');if(p)p.remove();console.log('LATERBOX_YOUTUBE_FAILED');}
        window.onYouTubeIframeAPIReady=function(){new YT.Player('player',{
          videoId:'$videoId',playerVars:{origin:'$origin',playsinline:1},
          events:{onReady:function(){console.log('LATERBOX_YOUTUBE_READY');},onError:function(){fallback();}}
        });};
        var s=document.createElement('script');s.src='https://www.youtube.com/iframe_api';s.onerror=fallback;document.head.appendChild(s);
        </script></body></html>
    """.trimIndent()
}

@Composable
internal fun YouTubeItemPreview(videoId: String) {
    val context = LocalContext.current
    val origin = remember(context.packageName) { "https://${context.packageName.lowercase()}" }
    val watchUrl = "https://www.youtube.com/watch?v=$videoId"
    var failed by remember(videoId) { mutableStateOf(false) }
    var ready by remember(videoId) { mutableStateOf(false) }
    var openFailed by remember(videoId) { mutableStateOf(false) }
    var browser by remember(videoId) { mutableStateOf<WebView?>(null) }
    val lifecycle = LocalLifecycleOwner.current.lifecycle
    LaunchedEffect(videoId) { delay(15000); if (!ready) failed = true }
    DisposableEffect(lifecycle) {
        val observer = LifecycleEventObserver { _, event ->
            if (event == Lifecycle.Event.ON_PAUSE) browser?.onPause()
            if (event == Lifecycle.Event.ON_RESUME) browser?.onResume()
        }
        lifecycle.addObserver(observer)
        onDispose { lifecycle.removeObserver(observer) }
    }
    if (!failed) key(videoId) {
        AndroidView(factory = { androidContext -> WebView(androidContext).apply {
            browser = this
            settings.javaScriptEnabled = true
            settings.domStorageEnabled = true
            settings.allowFileAccess = false
            settings.allowContentAccess = false
            settings.mediaPlaybackRequiresUserGesture = true
            webChromeClient = object : WebChromeClient() {
                override fun onConsoleMessage(message: ConsoleMessage?): Boolean {
                    when (message?.message()) {
                        "LATERBOX_YOUTUBE_READY" -> ready = true
                        "LATERBOX_YOUTUBE_FAILED" -> failed = true
                        else -> return false
                    }
                    return true
                }
            }
            webViewClient = object : WebViewClient() {
                override fun onReceivedError(view: WebView?, request: WebResourceRequest?, error: android.webkit.WebResourceError?) {
                    if (request?.isForMainFrame == true) failed = true
                }
                override fun onReceivedHttpError(view: WebView?, request: WebResourceRequest?, response: android.webkit.WebResourceResponse?) {
                    if (request?.isForMainFrame == true) failed = true
                }
                override fun shouldOverrideUrlLoading(view: WebView?, request: WebResourceRequest?): Boolean {
                    if (request?.isForMainFrame != true) return false
                    val uri = request.url
                    if (uri.scheme in listOf("http", "https")) runCatching { context.startActivity(Intent(Intent.ACTION_VIEW, uri)) }.onFailure { openFailed = true }
                    return true
                }
            }
            loadDataWithBaseURL("$origin/", youtubePlayerDocument(videoId, origin), "text/html", "UTF-8", null)
        } }, onRelease = { it.stopLoading(); it.loadUrl("about:blank"); it.destroy(); browser = null }, modifier = Modifier.fillMaxWidth().height(280.dp))
        if (!ready) LinearProgressIndicator(Modifier.fillMaxWidth())
    }
    Button(onClick = { runCatching { context.startActivity(Intent(Intent.ACTION_VIEW, Uri.parse(watchUrl))) }.onFailure { openFailed = true } }, modifier = Modifier.fillMaxWidth()) {
        Text("Play on YouTube")
    }
    if (openFailed) Text("A browser or the YouTube app is needed to play this video.")
}
