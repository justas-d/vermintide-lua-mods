SplashView.init = function (self, input_manager, world) end
SplashView._next_splash = function (self, override_skip) end
SplashView._update_video = function (self, gui, dt) end
SplashView._update_texture = function(...) end
SplashView.set_index = function (self, index) end
SplashView.update = function (self, dt) end
SplashView.render = function (self) end
SplashView.destroy = function (...) end
SplashView.video_complete = function (...) return true end
SplashView.is_completed = function (...) return true end

Log.Debug("Skipped intro")