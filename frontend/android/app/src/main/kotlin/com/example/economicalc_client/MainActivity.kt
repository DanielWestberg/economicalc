package com.example.economicalc_client

import com.tink.core.Tink
import com.tink.link.ui.CredentialsOperation
import com.tink.link.ui.LinkUser
import com.tink.link.ui.ProviderSelection
import com.tink.link.ui.TinkLinkError
import com.tink.link.ui.TinkLinkErrorInfo
import com.tink.link.ui.TinkLinkResult
import com.tink.link.ui.TinkLinkUiActivity
import com.tink.model.user.Scope
import com.tink.model.user.User
import com.tink.sample.configuration.Configuration
import com.tink.service.network.TinkConfiguration

import io.flutter.embedding.android.FlutterActivity

class MainActivity: FlutterActivity() {
    private val CHANNEL = "flutter.native/helper"

    @ExperimentalStdlibApi
    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler{
            call, result -> 
            when {
                call.method.equals("changeColor") -> {
                    changeColor(call, result)
                }
            }
        }
    }
    private fun changeColor(call: MethodCall, result: MethodChannel.Result) {
        var color = call.argument<String>("color");
        result.success(color);
    }
}
