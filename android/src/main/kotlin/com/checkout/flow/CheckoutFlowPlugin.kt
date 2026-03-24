package com.checkout.flow

import android.app.Activity
import androidx.lifecycle.Lifecycle
import androidx.lifecycle.LifecycleOwner
import androidx.lifecycle.LifecycleRegistry
import androidx.lifecycle.ViewModelStore
import androidx.lifecycle.ViewModelStoreOwner
import androidx.lifecycle.setViewTreeLifecycleOwner
import androidx.lifecycle.setViewTreeViewModelStoreOwner
import androidx.savedstate.SavedStateRegistry
import androidx.savedstate.SavedStateRegistryController
import androidx.savedstate.SavedStateRegistryOwner
import androidx.savedstate.setViewTreeSavedStateRegistryOwner
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding

/**
 * Provides all view tree owners needed by Jetpack Compose when the host Activity
 * (Flutter's FlutterActivity) doesn't natively set them on the DecorView.
 */
private class ComposeViewTreeOwner : LifecycleOwner, SavedStateRegistryOwner, ViewModelStoreOwner {
    private val lifecycleRegistry = LifecycleRegistry(this)
    private val savedStateRegistryController = SavedStateRegistryController.create(this)
    private val store = ViewModelStore()

    override val lifecycle: Lifecycle get() = lifecycleRegistry
    override val savedStateRegistry: SavedStateRegistry get() = savedStateRegistryController.savedStateRegistry
    override val viewModelStore: ViewModelStore get() = store

    init {
        savedStateRegistryController.performRestore(null)
        lifecycleRegistry.handleLifecycleEvent(Lifecycle.Event.ON_CREATE)
        lifecycleRegistry.handleLifecycleEvent(Lifecycle.Event.ON_START)
        lifecycleRegistry.handleLifecycleEvent(Lifecycle.Event.ON_RESUME)
    }

    fun destroy() {
        lifecycleRegistry.handleLifecycleEvent(Lifecycle.Event.ON_PAUSE)
        lifecycleRegistry.handleLifecycleEvent(Lifecycle.Event.ON_STOP)
        lifecycleRegistry.handleLifecycleEvent(Lifecycle.Event.ON_DESTROY)
        store.clear()
    }
}

class CheckoutFlowPlugin : FlutterPlugin, ActivityAware {
    private var factory: CheckoutFlowViewFactory? = null
    private var composeOwner: ComposeViewTreeOwner? = null

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        factory = CheckoutFlowViewFactory(binding.binaryMessenger)
        binding.platformViewRegistry.registerViewFactory(
            "checkout_flow_view",
            factory!!
        )
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        factory = null
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        factory?.activity = binding.activity

        val decorView = binding.activity.window?.decorView ?: return

        // Create our own owner that provides Lifecycle + SavedState + ViewModelStore
        val owner = ComposeViewTreeOwner()
        composeOwner = owner

        decorView.setViewTreeLifecycleOwner(owner)
        decorView.setViewTreeSavedStateRegistryOwner(owner)
        decorView.setViewTreeViewModelStoreOwner(owner)
    }

    override fun onDetachedFromActivity() {
        factory?.activity = null
        composeOwner?.destroy()
        composeOwner = null
    }

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        onAttachedToActivity(binding)
    }

    override fun onDetachedFromActivityForConfigChanges() {
        onDetachedFromActivity()
    }
}
