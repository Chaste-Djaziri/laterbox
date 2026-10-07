package com.example.laterbox.ui.screens

import android.graphics.Bitmap
import android.graphics.pdf.PdfRenderer
import android.media.MediaPlayer
import android.os.ParcelFileDescriptor
import android.webkit.WebView
import android.webkit.WebViewClient
import android.webkit.WebResourceRequest
import android.widget.MediaController
import android.widget.VideoView
import androidx.compose.foundation.Image
import androidx.compose.foundation.layout.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.asImageBitmap
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.unit.dp
import androidx.compose.ui.viewinterop.AndroidView
import androidx.lifecycle.Lifecycle
import androidx.lifecycle.LifecycleEventObserver
import androidx.lifecycle.compose.LocalLifecycleOwner
import coil.compose.AsyncImage
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import java.io.File
import java.net.HttpURLConnection
import java.net.URI
import java.net.URL

@Composable
internal fun ItemImagePreview(source: Any, label: String) {
    var failed by remember(source) { mutableStateOf(false) }
    AsyncImage(source, label, Modifier.fillMaxWidth().heightIn(min = 120.dp, max = 360.dp), contentScale = ContentScale.Fit, onError = { failed = true })
    if (failed) Text("Image preview unavailable. Open the original to view it.")
}

@Composable
internal fun ItemVideoPreview(source: String) {
    var error by remember(source) { mutableStateOf<String?>(null) }
    var view by remember(source) { mutableStateOf<VideoView?>(null) }
    val lifecycle = LocalLifecycleOwner.current.lifecycle
    DisposableEffect(lifecycle, view) {
        val observer = LifecycleEventObserver { _, event -> if (event == Lifecycle.Event.ON_PAUSE) view?.pause() }
        lifecycle.addObserver(observer)
        onDispose { lifecycle.removeObserver(observer); view?.stopPlayback() }
    }
    key(source) {
        AndroidView(factory = { context -> VideoView(context).apply {
            view = this
            setVideoURI(android.net.Uri.parse(source))
            setMediaController(MediaController(context).also { it.setAnchorView(this) })
            setOnErrorListener { _, _, _ -> error = "Video preview unavailable. Try opening the original."; true }
        } }, onRelease = { it.stopPlayback() }, modifier = Modifier.fillMaxWidth().height(240.dp))
    }
    error?.let { Text(it, color = MaterialTheme.colorScheme.error) }
}

@Composable
internal fun ItemAudioPreview(source: String) {
    var player by remember(source) { mutableStateOf<MediaPlayer?>(null) }
    var ready by remember(source) { mutableStateOf(false) }
    var playing by remember(source) { mutableStateOf(false) }
    var error by remember(source) { mutableStateOf<String?>(null) }
    val lifecycle = LocalLifecycleOwner.current.lifecycle
    DisposableEffect(source, lifecycle) {
        val audio = MediaPlayer()
        player = audio
        audio.setOnPreparedListener { ready = true }
        audio.setOnCompletionListener { playing = false }
        audio.setOnErrorListener { _, _, _ -> error = "Audio preview unavailable. Try opening the original."; playing = false; ready = false; true }
        runCatching { audio.setDataSource(source); audio.prepareAsync() }.onFailure { error = "Unable to load audio." }
        val observer = LifecycleEventObserver { _, event -> if (event == Lifecycle.Event.ON_PAUSE && ready) { audio.pause(); playing = false } }
        lifecycle.addObserver(observer)
        onDispose { lifecycle.removeObserver(observer); audio.release(); player = null }
    }
    if (error != null) Text(error!!, color = MaterialTheme.colorScheme.error)
    else Button(onClick = { runCatching { if (playing) player?.pause() else player?.start(); playing = !playing }.onFailure { error = "Unable to play audio." } }, enabled = ready) {
        Text(if (!ready) "Loading audio…" else if (playing) "Pause audio" else "Play audio")
    }
}

@Composable
internal fun HostedItemPreview(url: String) {
    var error by remember(url) { mutableStateOf(false) }
    var loading by remember(url) { mutableStateOf(true) }
    val lifecycle = LocalLifecycleOwner.current.lifecycle
    var browser by remember(url) { mutableStateOf<WebView?>(null) }
    DisposableEffect(lifecycle, browser) {
        val observer = LifecycleEventObserver { _, event ->
            if (event == Lifecycle.Event.ON_PAUSE) browser?.onPause()
            if (event == Lifecycle.Event.ON_RESUME) browser?.onResume()
        }
        lifecycle.addObserver(observer)
        onDispose { lifecycle.removeObserver(observer) }
    }
    key(url) {
        AndroidView(factory = { context -> WebView(context).apply {
            browser = this
            settings.javaScriptEnabled = true
            settings.domStorageEnabled = true
            settings.allowFileAccess = false
            settings.allowContentAccess = false
            settings.mediaPlaybackRequiresUserGesture = true
            webViewClient = object : WebViewClient() {
                override fun onPageFinished(view: WebView?, finished: String?) { loading = false }
                override fun onReceivedError(view: WebView?, request: WebResourceRequest?, failure: android.webkit.WebResourceError?) { if (request?.isForMainFrame == true) { error = true; loading = false } }
                override fun shouldOverrideUrlLoading(view: WebView?, request: WebResourceRequest?): Boolean {
                    val target = request?.url?.toString() ?: return true
                    if (request.isForMainFrame && target != url) {
                        if (runCatching { URI(target).scheme in listOf("http", "https") }.getOrDefault(false)) runCatching { context.startActivity(android.content.Intent(android.content.Intent.ACTION_VIEW, request.url)) }
                        return true
                    }
                    return false
                }
            }
            loadUrl(url)
        } }, onRelease = { it.stopLoading(); it.loadUrl("about:blank"); it.destroy(); browser = null }, modifier = Modifier.fillMaxWidth().height(280.dp))
    }
    if (loading) LinearProgressIndicator(Modifier.fillMaxWidth())
    if (error) Text("Embedded preview unavailable. Open the original instead.", color = MaterialTheme.colorScheme.error)
}

@Composable
internal fun ItemPdfPreview(file: File) {
    var page by remember(file.path) { mutableIntStateOf(0) }
    var count by remember(file.path) { mutableIntStateOf(0) }
    var error by remember(file.path) { mutableStateOf<String?>(null) }
    val bitmap by produceState<Bitmap?>(null, file.path, page) {
        value = null
        error = null
        try {
            value = withContext(Dispatchers.IO) {
                ParcelFileDescriptor.open(file, ParcelFileDescriptor.MODE_READ_ONLY).use { descriptor ->
                    PdfRenderer(descriptor).use { renderer ->
                        count = renderer.pageCount
                        renderer.openPage(page).use { pdfPage ->
                            val width = 1000
                            val height = (pdfPage.height.toFloat() / pdfPage.width * width).toInt().coerceIn(1, 2400)
                            Bitmap.createBitmap(width, height, Bitmap.Config.ARGB_8888).also { image ->
                                image.eraseColor(android.graphics.Color.WHITE)
                                pdfPage.render(image, null, null, PdfRenderer.Page.RENDER_MODE_FOR_DISPLAY)
                            }
                        }
                    }
                }
            }
        } catch (cancelled: kotlinx.coroutines.CancellationException) { throw cancelled }
        catch (_: Exception) { error = "PDF preview unavailable. The document may be encrypted or damaged." }
    }
    when {
        error != null -> Text(error!!, color = MaterialTheme.colorScheme.error)
        bitmap != null -> Image(bitmap!!.asImageBitmap(), "PDF page ${page + 1}", Modifier.fillMaxWidth().heightIn(max = 560.dp), contentScale = ContentScale.Fit)
        else -> CircularProgressIndicator()
    }
    Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween) {
        TextButton(onClick = { page-- }, enabled = page > 0) { Text("Previous") }
        Text("Page ${page + 1} of $count")
        TextButton(onClick = { page++ }, enabled = page + 1 < count) { Text("Next") }
    }
}

@Composable
internal fun RemoteItemPdfPreview(url: String) {
    val context = LocalContext.current
    var requested by remember(url) { mutableStateOf(false) }
    var error by remember(url) { mutableStateOf<String?>(null) }
    val file by produceState<File?>(null, url, requested) {
        if (!requested) return@produceState
        try {
            value = withContext(Dispatchers.IO) {
                val target = File(context.cacheDir, "exports/item-preview-${java.util.UUID.randomUUID()}.pdf")
                target.parentFile?.mkdirs()
                val connection = URL(url).openConnection() as HttpURLConnection
                try {
                    connection.connectTimeout = 15000; connection.readTimeout = 15000
                    check(connection.responseCode in 200..299)
                    connection.inputStream.use { input -> target.outputStream().use { output ->
                        val buffer = ByteArray(8192); var total = 0
                        while (true) { val read = input.read(buffer); if (read < 0) break; total += read; check(total <= 20 * 1024 * 1024) { "PDF exceeds the 20 MB preview limit." }; output.write(buffer, 0, read) }
                    } }
                    target
                } catch (failure: Exception) { target.delete(); throw failure }
                finally { connection.disconnect() }
            }
        } catch (cancelled: kotlinx.coroutines.CancellationException) { throw cancelled }
        catch (_: Exception) { error = "Unable to download PDF preview (maximum 20 MB). Open the original instead." }
    }
    DisposableEffect(file) { onDispose { file?.delete() } }
    when {
        file != null -> ItemPdfPreview(file!!)
        error != null -> Text(error!!, color = MaterialTheme.colorScheme.error)
        requested -> CircularProgressIndicator()
        else -> OutlinedButton(onClick = { requested = true }) { Text("Load PDF preview") }
    }
}
