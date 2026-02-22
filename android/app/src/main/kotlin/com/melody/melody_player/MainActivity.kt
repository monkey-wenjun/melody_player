package com.melody.melody_player

import com.ryanheise.audioservice.AudioServiceFragmentActivity
import android.os.Bundle
import android.app.Activity
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.util.Log
import androidx.core.content.FileProvider
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity: AudioServiceFragmentActivity() {
    
    private val CHANNEL = "com.melody.melody_player/install"
    private val TAG = "MainActivity"
    
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
    }
    
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "installApk" -> {
                    val filePath = call.argument<String>("filePath")
                    if (filePath != null) {
                        try {
                            installApk(filePath, result)
                        } catch (e: Exception) {
                            Log.e(TAG, "安装失败", e)
                            result.success(mapOf("success" to false, "error" to e.message))
                        }
                    } else {
                        result.success(mapOf("success" to false, "error" to "文件路径为空"))
                    }
                }
                else -> result.notImplemented()
            }
        }
    }
    
    private fun installApk(filePath: String, result: MethodChannel.Result) {
        Log.d(TAG, "开始安装 APK: $filePath")
        
        val file = File(filePath)
        if (!file.exists()) {
            Log.e(TAG, "APK 文件不存在: $filePath")
            result.success(mapOf("success" to false, "error" to "文件不存在"))
            return
        }
        
        // 使用 FileProvider 获取 content URI
        val apkUri: Uri = FileProvider.getUriForFile(
            this,
            "${packageName}.fileprovider",
            file
        )
        
        Log.d(TAG, "APK URI: $apkUri")
        
        // 创建安装 Intent
        val intent = Intent(Intent.ACTION_VIEW).apply {
            setDataAndType(apkUri, "application/vnd.android.package-archive")
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_GRANT_READ_URI_PERMISSION
        }
        
        // 授予所有可能处理此 Intent 的应用读取权限
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
            val resolveInfoList = packageManager.queryIntentActivities(intent, 0)
            for (resolveInfo in resolveInfoList) {
                val packageName = resolveInfo.activityInfo.packageName
                grantUriPermission(
                    packageName,
                    apkUri,
                    Intent.FLAG_GRANT_READ_URI_PERMISSION
                )
            }
        }
        
        // 启动安装界面
        try {
            startActivity(intent)
            Log.d(TAG, "安装界面已启动")
            result.success(mapOf("success" to true))
        } catch (e: Exception) {
            Log.e(TAG, "无法启动安装界面", e)
            result.success(mapOf("success" to false, "error" to e.message))
        }
    }
    
    // 处理返回键 - 将应用移入后台而不是销毁，保持音频播放
    override fun onBackPressed() {
        moveTaskToBack(true)
    }
    
    // 当用户通过手势（左滑/右滑）返回时，也移入后台
    override fun onUserLeaveHint() {
        super.onUserLeaveHint()
        // 应用将自动进入后台，前台服务继续运行
    }
}
