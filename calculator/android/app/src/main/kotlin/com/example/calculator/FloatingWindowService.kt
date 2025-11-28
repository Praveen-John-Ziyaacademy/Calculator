// FloatingWindowService.kt
package com.example.calculator

import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Intent
import android.os.Build
import android.os.IBinder
import android.view.Gravity
import android.view.MotionEvent
import android.view.View
import android.view.WindowManager
import android.widget.Button
import android.widget.GridLayout
import android.widget.LinearLayout
import android.widget.TextView
import android.graphics.Color
import androidx.core.app.NotificationCompat

class FloatingWindowService : Service() {
    private lateinit var windowManager: WindowManager
    private var floatingView: LinearLayout? = null
    private var params: WindowManager.LayoutParams? = null
    private var initialX: Int = 0
    private var initialY: Int = 0
    private var initialTouchX: Float = 0f
    private var initialTouchY: Float = 0f
    private var currentInput = ""
    private var currentResult = "0"
    private lateinit var inputDisplay: TextView
    private lateinit var resultDisplay: TextView

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onCreate() {
        super.onCreate()
        windowManager = getSystemService(WINDOW_SERVICE) as WindowManager
        createNotificationChannel()
        createFloatingWindow()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        startForeground(1, createNotification())
        return START_STICKY
    }

    private fun createNotificationChannel() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channel = NotificationChannel(
                "floating_window_channel",
                "Floating Calculator",
                NotificationManager.IMPORTANCE_DEFAULT
            )
            val manager = getSystemService(NotificationManager::class.java)
            manager.createNotificationChannel(channel)
        }
    }

    private fun createNotification() =
        NotificationCompat.Builder(this, "floating_window_channel")
            .setContentTitle("Calculator")
            .setContentText("Running in floating window mode")
            .setSmallIcon(android.R.drawable.ic_dialog_info)
            .setContentIntent(
                PendingIntent.getActivity(
                    this, 0,
                    Intent(this, MainActivity::class.java),
                    PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
                )
            )
            .build()

    private fun createFloatingWindow() {
        try {
            // Create main container
            floatingView = LinearLayout(this).apply {
                orientation = LinearLayout.VERTICAL
                setBackgroundColor(Color.WHITE)
            }

            // Create header with back button and close button
            val header = LinearLayout(this).apply {
                orientation = LinearLayout.HORIZONTAL
                layoutParams = LinearLayout.LayoutParams(
                    LinearLayout.LayoutParams.MATCH_PARENT,
                    80
                )
                setBackgroundColor(Color.parseColor("#FF9800"))
                gravity = Gravity.CENTER_VERTICAL
                setPadding(12, 12, 12, 12)
            }

            val backButton = Button(this).apply {
                text = "←"
                layoutParams = LinearLayout.LayoutParams(
                    80,
                    80
                )
                setTextColor(Color.WHITE)
                setBackgroundColor(Color.parseColor("#FF9800"))
                textSize = 20f
                setOnClickListener {
                    // Bring app back to fullscreen
                    val intent = Intent(this@FloatingWindowService, MainActivity::class.java)
                    intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_REORDER_TO_FRONT
                    startActivity(intent)
                    stopSelf()
                }
            }
            header.addView(backButton)

            val spacer = View(this).apply {
                layoutParams = LinearLayout.LayoutParams(
                    0,
                    LinearLayout.LayoutParams.MATCH_PARENT,
                    1f
                )
            }
            header.addView(spacer)

            val closeButton = Button(this).apply {
                text = "✕"
                layoutParams = LinearLayout.LayoutParams(
                    80,
                    80
                )
                setTextColor(Color.WHITE)
                setBackgroundColor(Color.parseColor("#FF9800"))
                textSize = 20f
                setOnClickListener {
                    stopSelf()
                }
            }
            header.addView(closeButton)
            floatingView?.addView(header)

            // Create display area
            val displayContainer = LinearLayout(this).apply {
                orientation = LinearLayout.VERTICAL
                layoutParams = LinearLayout.LayoutParams(
                    LinearLayout.LayoutParams.MATCH_PARENT,
                    LinearLayout.LayoutParams.WRAP_CONTENT
                )
                setBackgroundColor(Color.parseColor("#F5F5F5"))
                gravity = Gravity.END or Gravity.BOTTOM
                setPadding(24, 16, 24, 16)
            }

            inputDisplay = TextView(this).apply {
                text = currentInput.ifEmpty { "0" }
                textSize = 16f
                setTextColor(Color.parseColor("#999999"))
                gravity = Gravity.END
                layoutParams = LinearLayout.LayoutParams(
                    LinearLayout.LayoutParams.MATCH_PARENT,
                    LinearLayout.LayoutParams.WRAP_CONTENT
                )
            }
            displayContainer.addView(inputDisplay)

            resultDisplay = TextView(this).apply {
                text = currentResult
                textSize = 32f
                setTextColor(Color.BLACK)
                layoutParams = LinearLayout.LayoutParams(
                    LinearLayout.LayoutParams.MATCH_PARENT,
                    LinearLayout.LayoutParams.WRAP_CONTENT
                )
                gravity = Gravity.END
            }
            displayContainer.addView(resultDisplay)
            floatingView?.addView(displayContainer)

            // Create buttons grid
            val buttonsContainer = LinearLayout(this).apply {
                orientation = LinearLayout.VERTICAL
                layoutParams = LinearLayout.LayoutParams(
                    LinearLayout.LayoutParams.MATCH_PARENT,
                    LinearLayout.LayoutParams.WRAP_CONTENT
                )
                setBackgroundColor(Color.WHITE)
                setPadding(8, 8, 8, 8)
            }

            // Row 1: AC, ⌫, %, ÷
            val row1 = LinearLayout(this).apply {
                orientation = LinearLayout.HORIZONTAL
                layoutParams = LinearLayout.LayoutParams(
                    LinearLayout.LayoutParams.MATCH_PARENT,
                    LinearLayout.LayoutParams.WRAP_CONTENT
                )
            }
            row1.addView(createButton("AC", "#FF9800", 1f) { clearAll() })
            row1.addView(createButton("⌫", "#FF9800", 1f) { deleteLastChar() })
            row1.addView(createButton("%", "#FF9800", 1f) { appendInput("%") })
            row1.addView(createButton("÷", "#FF9800", 1f) { appendInput("÷") })
            buttonsContainer.addView(row1)

            // Row 2: 7, 8, 9, ×
            val row2 = LinearLayout(this).apply {
                orientation = LinearLayout.HORIZONTAL
                layoutParams = LinearLayout.LayoutParams(
                    LinearLayout.LayoutParams.MATCH_PARENT,
                    LinearLayout.LayoutParams.WRAP_CONTENT
                )
            }
            row2.addView(createButton("7", "#000000", 1f) { appendInput("7") })
            row2.addView(createButton("8", "#000000", 1f) { appendInput("8") })
            row2.addView(createButton("9", "#000000", 1f) { appendInput("9") })
            row2.addView(createButton("×", "#FF9800", 1f) { appendInput("×") })
            buttonsContainer.addView(row2)

            // Row 3: 4, 5, 6, -
            val row3 = LinearLayout(this).apply {
                orientation = LinearLayout.HORIZONTAL
                layoutParams = LinearLayout.LayoutParams(
                    LinearLayout.LayoutParams.MATCH_PARENT,
                    LinearLayout.LayoutParams.WRAP_CONTENT
                )
            }
            row3.addView(createButton("4", "#000000", 1f) { appendInput("4") })
            row3.addView(createButton("5", "#000000", 1f) { appendInput("5") })
            row3.addView(createButton("6", "#000000", 1f) { appendInput("6") })
            row3.addView(createButton("-", "#FF9800", 1f) { appendInput("-") })
            buttonsContainer.addView(row3)

            // Row 4: 1, 2, 3, +
            val row4 = LinearLayout(this).apply {
                orientation = LinearLayout.HORIZONTAL
                layoutParams = LinearLayout.LayoutParams(
                    LinearLayout.LayoutParams.MATCH_PARENT,
                    LinearLayout.LayoutParams.WRAP_CONTENT
                )
            }
            row4.addView(createButton("1", "#000000", 1f) { appendInput("1") })
            row4.addView(createButton("2", "#000000", 1f) { appendInput("2") })
            row4.addView(createButton("3", "#000000", 1f) { appendInput("3") })
            row4.addView(createButton("+", "#FF9800", 1f) { appendInput("+") })
            buttonsContainer.addView(row4)

            // Row 5: 0, ., =
            val row5 = LinearLayout(this).apply {
                orientation = LinearLayout.HORIZONTAL
                layoutParams = LinearLayout.LayoutParams(
                    LinearLayout.LayoutParams.MATCH_PARENT,
                    LinearLayout.LayoutParams.WRAP_CONTENT
                )
            }
            row5.addView(createButton("0", "#000000", 2f) { appendInput("0") })
            row5.addView(createButton(".", "#000000", 1f) { appendInput(".") })
            row5.addView(createButton("=", "#4CAF50", 1f) { calculate() })
            buttonsContainer.addView(row5)

            floatingView?.addView(buttonsContainer)

            params = WindowManager.LayoutParams().apply {
                type = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    WindowManager.LayoutParams.TYPE_APPLICATION_OVERLAY
                } else {
                    @Suppress("DEPRECATION")
                    WindowManager.LayoutParams.TYPE_PHONE
                }
                format = android.graphics.PixelFormat.RGBA_8888
                flags = WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE
                width = 380
                height = 600
                x = 100
                y = 100
                gravity = Gravity.TOP or Gravity.START
            }

            setupFloatingViewListeners()
            windowManager.addView(floatingView, params)
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }

    private fun createButton(label: String, colorHex: String, weight: Float, onClick: () -> Unit): Button {
        val button = Button(this).apply {
            text = label
            layoutParams = LinearLayout.LayoutParams(
                0,
                120,
                weight
            ).apply {
                setMargins(6, 6, 6, 6)
            }
            textSize = 16f
            setTextColor(
                if (colorHex == "#FF9800") Color.WHITE 
                else if (colorHex == "#4CAF50") Color.WHITE
                else Color.BLACK
            )
            setBackgroundColor(Color.parseColor(colorHex))
            setOnClickListener {
                onClick()
            }
        }
        return button
    }

    private fun appendInput(value: String) {
        currentInput += value
        inputDisplay.text = currentInput
    }

    private fun deleteLastChar() {
        if (currentInput.isNotEmpty()) {
            currentInput = currentInput.dropLast(1)
            inputDisplay.text = currentInput.ifEmpty { "0" }
        }
    }

    private fun clearAll() {
        currentInput = ""
        currentResult = "0"
        inputDisplay.text = "0"
        resultDisplay.text = "0"
    }

    private fun calculate() {
        try {
            val expression = currentInput
                .replace("÷", "/")
                .replace("×", "*")
            
            if (expression.isNotEmpty()) {
                val result = eval(expression)
                currentResult = result.toString()
                resultDisplay.text = currentResult
                currentInput = ""
                inputDisplay.text = "0"
            }
        } catch (e: Exception) {
            resultDisplay.text = "Error"
        }
    }

    private fun eval(expression: String): Double {
        return object : Any() {
            var pos = -1
            var ch = 0

            fun parse(expression: String): Double {
                pos = -1
                ch = 0
                nextChar(expression)
                return parseExpression(expression)
            }

            fun nextChar(expression: String) {
                pos++
                ch = if (pos < expression.length) expression[pos].code else -1
            }

            fun eat(charToEat: Int, expression: String): Boolean {
                while (ch == ' '.code) nextChar(expression)
                if (ch == charToEat) {
                    nextChar(expression)
                    return true
                }
                return false
            }

            fun parseExpression(expression: String): Double {
                var result = parseTerm(expression)
                while (true) {
                    when {
                        eat('+'.code, expression) -> result += parseTerm(expression)
                        eat('-'.code, expression) -> result -= parseTerm(expression)
                        else -> return result
                    }
                }
            }

            fun parseTerm(expression: String): Double {
                var result = parseFactor(expression)
                while (true) {
                    when {
                        eat('*'.code, expression) -> result *= parseFactor(expression)
                        eat('/'.code, expression) -> result /= parseFactor(expression)
                        eat('%'.code, expression) -> result %= parseFactor(expression)
                        else -> return result
                    }
                }
            }

            fun parseFactor(expression: String): Double {
                if (eat('+'.code, expression)) return parseFactor(expression)
                if (eat('-'.code, expression)) return -parseFactor(expression)
                var result: Double
                val startPos = pos
                if (ch == '('.code) {
                    nextChar(expression)
                    result = parseExpression(expression)
                    eat(')'.code, expression)
                } else if (ch in '0'.code..'9'.code || ch == '.'.code) {
                    while (ch in '0'.code..'9'.code || ch == '.'.code) nextChar(expression)
                    result = expression.substring(startPos, pos).toDouble()
                } else {
                    throw RuntimeException("Unexpected: " + ch.toChar())
                }
                return result
            }
        }.parse(expression)
    }

    private fun setupFloatingViewListeners() {
        floatingView?.setOnTouchListener { _, event ->
            when (event.action) {
                MotionEvent.ACTION_DOWN -> {
                    initialX = params!!.x
                    initialY = params!!.y
                    initialTouchX = event.rawX
                    initialTouchY = event.rawY
                    true
                }
                MotionEvent.ACTION_MOVE -> {
                    val deltaX = (event.rawX - initialTouchX).toInt()
                    val deltaY = (event.rawY - initialTouchY).toInt()

                    params!!.x = initialX + deltaX
                    params!!.y = initialY + deltaY
                    windowManager.updateViewLayout(floatingView, params)
                    true
                }
                else -> false
            }
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        if (floatingView != null) {
            windowManager.removeView(floatingView)
        }
    }
}