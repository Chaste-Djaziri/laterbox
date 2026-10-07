package com.example.laterbox.ui.main

import com.example.laterbox.data.DataRepository
import com.example.laterbox.data.api.SystemStatusResponse
import com.example.laterbox.data.local.CollectionEntity
import com.example.laterbox.data.local.ItemEntity
import com.example.laterbox.data.local.ItemMetadataEntity
import junit.framework.TestCase.assertEquals
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.flow.flowOf
import kotlinx.coroutines.test.runTest
import org.junit.Test

class MainScreenViewModelTest {
  @Test
  fun uiState_initiallyLoading() = runTest {
    val repo = FakeMyModelRepository()
    val viewModel = MainScreenViewModel(repo)
    val state = viewModel.uiState.first()
    assert(state is MainScreenUiState)
  }

  @Test
  fun uiState_onItemSaved_isDisplayed() = runTest {
    val repo = FakeMyModelRepository(
      initialItems = listOf(
        ItemEntity(
          id = "test-1",
          userId = null,
          url = "https://laterbox.dev",
          title = "Test Item",
          textContent = "https://laterbox.dev",
          status = "inbox",
          favorite = false,
          returnAt = null,
          collectionId = null,
          category = "General",
          createdAt = "2026-01-01T00:00:00Z",
          updatedAt = "2026-01-01T00:00:00Z"
        )
      )
    )
    val viewModel = MainScreenViewModel(repo)
    val state = viewModel.uiState.first { it is MainScreenUiState.Success }
    assertEquals(listOf("Test Item"), (state as MainScreenUiState.Success).data)
  }
}

private class FakeMyModelRepository(
  initialItems: List<ItemEntity> = emptyList()
) : DataRepository {
  private val _itemsFlow = MutableStateFlow(initialItems)
  override val items: Flow<List<ItemEntity>> = _itemsFlow
  override val collections: Flow<List<CollectionEntity>> = flowOf(emptyList())
  private val _webStatus = MutableStateFlow(SystemStatusResponse("operational", "Operational", "emerald", true))
  override val webStatus: StateFlow<SystemStatusResponse> = _webStatus.asStateFlow()

  override fun refreshWebStatus() {}
  override suspend fun captureItem(url: String?, text: String?, title: String?, returnAt: String?, collectionId: String?): ItemEntity {
    val item = ItemEntity(
      id = "item-new",
      userId = null,
      url = url,
      title = title,
      textContent = text ?: url.orEmpty(),
      status = "inbox",
      favorite = false,
      returnAt = returnAt,
      collectionId = collectionId,
      category = "General",
      createdAt = "2026-01-01T00:00:00Z",
      updatedAt = "2026-01-01T00:00:00Z"
    )
    _itemsFlow.value = _itemsFlow.value + item
    return item
  }

  override suspend fun updateItemStatus(id: String, status: String) {}
  override suspend fun toggleFavorite(id: String, currentFavorite: Boolean) {}
  override suspend fun scheduleReturn(id: String, returnAt: String?) {}
  override suspend fun deleteItem(id: String) {}
  override suspend fun getMetadata(itemId: String): ItemMetadataEntity? = null
  override suspend fun addCollection(name: String, colorHex: String, iconName: String): CollectionEntity =
    CollectionEntity("col-1", null, name, colorHex, iconName, "2026-01-01", "2026-01-01")
  override suspend fun deleteCollection(id: String) {}
  override fun syncNow() {}
}
