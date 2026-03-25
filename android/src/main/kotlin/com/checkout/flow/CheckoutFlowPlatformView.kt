package com.checkout.flow

import android.content.Context
import android.os.Handler
import android.os.Looper
import android.util.Log
import android.view.View
import android.view.ViewGroup
import android.widget.FrameLayout
import com.checkout.components.core.CheckoutComponentsFactory
import com.checkout.components.interfaces.model.ComponentName
import com.checkout.components.interfaces.component.CheckoutComponentConfiguration
import com.checkout.components.interfaces.model.PaymentSessionResponse
import com.checkout.components.interfaces.Environment
import com.checkout.components.interfaces.component.ComponentCallback
import com.checkout.components.interfaces.model.CallbackResult
import com.checkout.components.interfaces.model.TokenizationResult
import com.checkout.components.interfaces.model.PaymentMethodName
import com.checkout.components.interfaces.component.ComponentOption
import com.checkout.components.interfaces.component.PaymentButtonAction
import com.checkout.components.interfaces.localisation.Locale as CkoLocale
import com.checkout.components.interfaces.uicustomisation.designtoken.ColorTokens
import com.checkout.components.interfaces.uicustomisation.designtoken.DesignTokens
import com.checkout.components.interfaces.uicustomisation.BorderRadius
import androidx.compose.ui.graphics.Color
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.platform.PlatformView
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch

class CheckoutFlowPlatformView(
    private val context: Context,
    viewId: Int,
    messenger: BinaryMessenger,
    private val params: Map<String, Any?>
) : PlatformView {

    private val channel = MethodChannel(messenger, "checkout_flow_view_$viewId")
    private var lastReportedHeight = 0
    private val containerView = FrameLayout(context).apply {
        layoutParams = ViewGroup.LayoutParams(
            ViewGroup.LayoutParams.MATCH_PARENT,
            ViewGroup.LayoutParams.WRAP_CONTENT
        )
    }
    private val mainHandler = Handler(Looper.getMainLooper())
    private val TAG = "CheckoutFlow"

    private val heightCheckRunnable = object : Runnable {
        override fun run() {
            checkAndReportHeight()
            mainHandler.postDelayed(this, 300)
        }
    }

    init {
        setupFlow()
        // Start polling for height changes (Compose views don't trigger layout change on parent reliably)
        mainHandler.postDelayed(heightCheckRunnable, 500)
    }

    private fun checkAndReportHeight() {
        for (i in 0 until containerView.childCount) {
            val child = containerView.getChildAt(i)
            // Force measure if needed
            if (child.measuredHeight == 0) {
                child.measure(
                    View.MeasureSpec.makeMeasureSpec(containerView.width, View.MeasureSpec.AT_MOST),
                    View.MeasureSpec.makeMeasureSpec(0, View.MeasureSpec.UNSPECIFIED)
                )
            }
            val heightPx = maxOf(child.height, child.measuredHeight)
            if (heightPx > 0) {
                val density = context.resources.displayMetrics.density
                val heightDp = (heightPx / density).toInt()
                if (heightDp > 0 && heightDp != lastReportedHeight) {
                    lastReportedHeight = heightDp
                    Log.d(TAG, "Height changed: ${heightDp}dp (px=$heightPx, measured=${child.measuredHeight}, actual=${child.height})")
                    invokeOnMain("onHeightChanged", mapOf("height" to heightDp.toDouble()))
                }
                return
            }
        }
    }

    private fun invokeOnMain(method: String, arguments: Any?) {
        mainHandler.post {
            channel.invokeMethod(method, arguments)
        }
    }

    private fun setupFlow() {
        try {
            val publicKey = params["publicKey"] as? String
                ?: return invokeOnMain("onError", mapOf("errorCode" to "INVALID_PARAMS", "message" to "Missing publicKey"))
            val paymentSessionId = params["paymentSessionId"] as? String
                ?: return invokeOnMain("onError", mapOf("errorCode" to "INVALID_PARAMS", "message" to "Missing paymentSessionId"))
            val paymentSessionSecret = params["paymentSessionSecret"] as? String
                ?: return invokeOnMain("onError", mapOf("errorCode" to "INVALID_PARAMS", "message" to "Missing paymentSessionSecret"))
            val envName = params["environment"] as? String ?: "sandbox"

            val environment = when (envName) {
                "production" -> Environment.PRODUCTION
                else -> Environment.SANDBOX
            }

            val localeStr = params["locale"] as? String
            val ckoLocale: CkoLocale? = when (localeStr?.take(2)?.lowercase()) {
                "it" -> CkoLocale.It
                "en" -> CkoLocale.En
                "de" -> CkoLocale.De
                "fr" -> CkoLocale.Fr
                "es" -> CkoLocale.Es
                "pt" -> CkoLocale.Pt
                "nl" -> CkoLocale.Nl
                "ar" -> CkoLocale.Ar
                "da" -> CkoLocale.Da
                "el" -> CkoLocale.El
                "fi" -> CkoLocale.Fi
                "hi" -> CkoLocale.Hi
                "id" -> CkoLocale.Id
                "ja" -> CkoLocale.Ja
                "ms" -> CkoLocale.Ms
                "nb" -> CkoLocale.Nb
                "sv" -> CkoLocale.Sv
                "th" -> CkoLocale.Th
                "vi" -> CkoLocale.Vi
                "zh" -> CkoLocale.Zh
                else -> null
            }

            // Parse style colors from params
            val styleMap = params["theme"] as? Map<String, Any?>
            val appearance = if (styleMap != null) {
                val colorTokens = ColorTokens(
                    colorAction = parseColor(styleMap["actionColor"] as? String),
                    colorBackground = parseColor(styleMap["backgroundColor"] as? String),
                    colorPrimary = parseColor(styleMap["primaryColor"] as? String),
                    colorFormBackground = parseColor(styleMap["formBackgroundColor"] as? String),
                    colorFormBorder = parseColor(styleMap["formBorderColor"] as? String),
                    colorBorder = parseColor(styleMap["borderColor"] as? String),
                    colorError = parseColor(styleMap["errorColor"] as? String),
                    colorSuccess = parseColor(styleMap["successColor"] as? String),
                )
                val borderFormRadius = (styleMap["borderFormRadius"] as? Number)?.toInt()
                val borderButtonRadius = (styleMap["borderButtonRadius"] as? Number)?.toInt()
                DesignTokens(
                    colorTokens,
                    emptyMap(),
                    if (borderFormRadius != null) BorderRadius(borderFormRadius) else BorderRadius(),
                    if (borderButtonRadius != null) BorderRadius(borderButtonRadius) else BorderRadius(),
                )
            } else null

            val tokenOnly = params["tokenOnly"] as? Boolean ?: false

            // Build componentOptions with TOKENIZE action when tokenOnly mode
            val componentOptions = if (tokenOnly) {
                mapOf(
                    PaymentMethodName.Card to ComponentOption(
                        paymentButtonAction = PaymentButtonAction.TOKENIZE
                    )
                )
            } else {
                emptyMap()
            }

            val config = CheckoutComponentConfiguration(
                context = context,
                publicKey = publicKey,
                environment = environment,
                locale = ckoLocale,
                // appearance = appearance,  // TODO: fix color conversion for Compose Color format
                paymentSession = PaymentSessionResponse(
                    id = paymentSessionId,
                    secret = paymentSessionSecret
                ),
                componentOptions = componentOptions,
                componentCallback = ComponentCallback(
                    onSuccess = { _, paymentId ->
                        invokeOnMain("onSuccess", mapOf("paymentId" to paymentId))
                    },
                    onError = { _, error ->
                        invokeOnMain("onError", mapOf(
                            "errorCode" to "PAYMENT_ERROR",
                            "message" to (error.message ?: "Payment error")
                        ))
                    },
                    onTokenized = { result: TokenizationResult ->
                        val token = result.data?.token ?: ""
                        Log.d(TAG, "Tokenized: token=$token, type=${result.type}, scheme=${result.preferredScheme}")
                        invokeOnMain("onTokenized", mapOf(
                            "token" to token,
                            "type" to (result.type ?: ""),
                            "preferredScheme" to (result.preferredScheme ?: "")
                        ))
                        CallbackResult.Accepted
                    }
                )
            )

            CoroutineScope(Dispatchers.Main).launch {
                try {
                    Log.d(TAG, "Creating CheckoutComponentsFactory...")
                    val checkoutComponents = CheckoutComponentsFactory(config).create()
                    val componentType = params["componentType"] as? String ?: "flow"
                    val component = if (componentType == "card") {
                        Log.d(TAG, "Factory created, creating Card component...")
                        checkoutComponents.create(PaymentMethodName.Card)
                    } else {
                        Log.d(TAG, "Factory created, creating Flow component...")
                        checkoutComponents.create(ComponentName.Flow)
                    }
                    Log.d(TAG, "$componentType component created, rendering via ComposeView...")

                    // Use provideView which returns a ComposeView
                    // Pass a dummy FrameLayout, then use the returned view
                    val dummyParent = FrameLayout(context)
                    val renderedView = component.provideView(dummyParent)

                    // The rendered view is a ComposeView - add it to our container
                    if (renderedView != null) {
                        // Remove from dummy parent if attached
                        (renderedView.parent as? ViewGroup)?.removeView(renderedView)
                        containerView.addView(renderedView, ViewGroup.LayoutParams(
                            ViewGroup.LayoutParams.MATCH_PARENT,
                            ViewGroup.LayoutParams.WRAP_CONTENT
                        ))
                    }
                    Log.d(TAG, "ComposeView added to container")
                    invokeOnMain("onReady", null)
                } catch (e: Exception) {
                    Log.e(TAG, "Error initializing checkout: ${e.message}", e)
                    invokeOnMain(
                        "onError",
                        mapOf("errorCode" to "INIT_ERROR", "message" to (e.message ?: "Checkout initialization error"))
                    )
                }
            }
        } catch (e: Exception) {
            invokeOnMain(
                "onError",
                mapOf("errorCode" to "UNKNOWN", "message" to (e.message ?: "Unknown error"))
            )
        }
    }

    /**
     * Parse hex color string (#RRGGBB or #AARRGGBB) to Compose Color Long value.
     */
    private fun parseColor(hex: String?): Long {
        if (hex == null) return Color.Unspecified.value.toLong()
        return try {
            val clean = hex.removePrefix("#")
            val argbInt = when (clean.length) {
                6 -> (0xFF000000 or java.lang.Long.parseLong(clean, 16)).toInt()
                8 -> java.lang.Long.parseLong(clean, 16).toInt()
                else -> android.graphics.Color.BLACK
            }
            Color(argbInt).value.toLong()
        } catch (e: Exception) {
            Color.Unspecified.value.toLong()
        }
    }

    override fun getView(): View = containerView

    override fun dispose() {
        mainHandler.removeCallbacks(heightCheckRunnable)
    }
}
