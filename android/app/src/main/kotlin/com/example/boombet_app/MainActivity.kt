package com.example.boombet_app

import android.content.Intent
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {

	companion object {
		private const val CHANNEL_DEEP_LINK = "boombet/deep_links"
		private const val METHOD_ON_DEEP_LINK = "onDeepLink"
	}

	private var deepLinkChannel: MethodChannel? = null
	private var pendingDeepLinkPayload: Map<String, String?>? = null

	override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
		super.configureFlutterEngine(flutterEngine)
		deepLinkChannel = MethodChannel(
			flutterEngine.dartExecutor.binaryMessenger,
			CHANNEL_DEEP_LINK
		)

		pendingDeepLinkPayload?.let { payload ->
			deepLinkChannel?.invokeMethod(METHOD_ON_DEEP_LINK, payload)
			pendingDeepLinkPayload = null
		}
	}

	override fun onCreate(savedInstanceState: Bundle?) {
		super.onCreate(savedInstanceState)
		handleIntent(intent)
	}

	override fun onNewIntent(intent: Intent) {
		super.onNewIntent(intent)
		setIntent(intent)
		handleIntent(intent)
	}

	private fun handleIntent(intent: Intent?) {
		if (intent?.action != Intent.ACTION_VIEW) return

		val data = intent.data ?: return

		val payload = mapOf(
			"uri" to data.toString(),
			"scheme" to data.scheme,
			"host" to data.host,
			"path" to data.path,
			"query" to data.query,
			"token" to data.getQueryParameter("token")
		)

		val channel = deepLinkChannel
		if (channel == null) {
			pendingDeepLinkPayload = payload
		} else {
			channel.invokeMethod(METHOD_ON_DEEP_LINK, payload)
		}
	}
}
