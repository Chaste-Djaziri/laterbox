package com.example.laterbox

import android.app.Activity
import android.content.Intent
import android.graphics.Color
import android.graphics.Typeface
import android.net.Uri
import android.os.Bundle
import android.util.TypedValue
import android.view.Gravity
import android.view.View
import android.view.ViewGroup
import android.widget.Button
import android.widget.LinearLayout
import android.widget.ProgressBar
import android.widget.TextView

class ShareReceiverActivity : Activity() {

    private lateinit var pendingShares: PendingShareQueue
    private lateinit var spinner: ProgressBar
    private lateinit var icon: TextView
    private lateinit var title: TextView
    private lateinit var subtitle: TextView
    private lateinit var actions: LinearLayout

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        pendingShares = PendingShareQueue(applicationContext)
        buildView()
        showSaving()
        handleShare(intent)
    }

    private fun buildView() {
        val content = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.CENTER
            setPadding(dp(40), dp(40), dp(40), dp(40))
        }

        spinner = ProgressBar(this)
        spinner.visibility = View.GONE

        icon = TextView(this).apply {
            textSize = 44f
            gravity = Gravity.CENTER
            visibility = View.GONE
        }

        title = TextView(this).apply {
            textSize = 18f
            setTextColor(resolveAttr(android.R.attr.textColorPrimary))
            gravity = Gravity.CENTER
            typeface = Typeface.DEFAULT_BOLD
        }

        subtitle = TextView(this).apply {
            textSize = 14f
            setTextColor(resolveAttr(android.R.attr.textColorSecondary))
            gravity = Gravity.CENTER
            maxLines = 2
        }

        actions = LinearLayout(this).apply {
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER
            visibility = View.GONE
        }

        val cancel = Button(this).apply {
            text = "Cancel"
            setOnClickListener { finish() }
        }
        val retry = Button(this).apply {
            text = "Try again"
            setOnClickListener {
                actions.visibility = View.GONE
                showSaving()
                handleShare(intent)
            }
        }
        actions.addView(cancel)
        actions.addView(retry)

        content.addView(spinner, centerParams())
        content.addView(icon, centerParams())
        content.addView(title, labelParams(topMargin = dp(8)))
        content.addView(subtitle, labelParams(topMargin = dp(4)))
        content.addView(actions, labelParams(topMargin = dp(20)))

        setContentView(content)
    }

    private fun handleShare(intent: Intent?) {
        if (intent?.action != Intent.ACTION_SEND || intent.type != "text/plain") {
            showFailure("No text content shared")
            return
        }

        val text = intent.getStringExtra(Intent.EXTRA_TEXT)
            ?.trim()
            ?.takeIf { it.isNotEmpty() }

        if (text == null) {
            showFailure("No text content shared")
            return
        }

        if (pendingShares.enqueue(text)) {
            showSuccess(subtitle = displaySubtitle(text))
        } else {
            showFailure("Couldn't write to LaterBox storage")
        }
    }

    private fun showSaving() {
        actions.visibility = View.GONE
        icon.visibility = View.GONE
        subtitle.visibility = View.GONE
        spinner.visibility = View.VISIBLE
        title.text = "Saving…"
    }

    private fun showSuccess(subtitle: String?) {
        actions.visibility = View.GONE
        spinner.visibility = View.GONE
        icon.visibility = View.VISIBLE
        icon.text = "✓"
        icon.setTextColor(Color.parseColor("#34C759"))
        title.text = "Saved to LaterBox"
        this.subtitle.text = subtitle ?: ""
        this.subtitle.visibility = if (subtitle == null) View.GONE else View.VISIBLE
        window.decorView.postDelayed({ finish() }, 800)
    }

    private fun showFailure(message: String) {
        spinner.visibility = View.GONE
        icon.visibility = View.VISIBLE
        icon.text = "!"
        icon.setTextColor(Color.parseColor("#FF3B30"))
        title.text = "Couldn't save"
        subtitle.text = message
        subtitle.visibility = View.VISIBLE
        actions.visibility = View.VISIBLE
    }

    private fun displaySubtitle(value: String): String? {
        val trimmed = value.trim()
        val host = if (trimmed.startsWith("http://") || trimmed.startsWith("https://")) {
            runCatching { Uri.parse(trimmed).host }.getOrNull()
        } else {
            null
        }
        if (!host.isNullOrEmpty()) return host.removePrefix("www.")
        return trimmed.take(60).ifEmpty { null }
    }

    private fun centerParams(): LinearLayout.LayoutParams =
        LinearLayout.LayoutParams(ViewGroup.LayoutParams.WRAP_CONTENT, ViewGroup.LayoutParams.WRAP_CONTENT)

    private fun labelParams(topMargin: Int): LinearLayout.LayoutParams =
        LinearLayout.LayoutParams(ViewGroup.LayoutParams.WRAP_CONTENT, ViewGroup.LayoutParams.WRAP_CONTENT).apply {
            this.topMargin = topMargin
        }

    private fun resolveAttr(attr: Int): Int {
        val typedValue = TypedValue()
        theme.resolveAttribute(attr, typedValue, true)
        return typedValue.data
    }

    private fun dp(value: Int): Int = (value * resources.displayMetrics.density).toInt()
}
