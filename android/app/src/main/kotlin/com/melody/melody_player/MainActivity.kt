package com.melody.melody_player

import com.ryanheise.audioservice.AudioServiceFragmentActivity
import android.os.Bundle
import android.app.Activity
import android.content.Intent

class MainActivity: AudioServiceFragmentActivity() {
    
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
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
