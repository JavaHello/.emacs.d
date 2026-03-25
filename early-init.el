(setq load-prefer-newer t)
(setq inhibit-startup-screen t)

(menu-bar-mode -1)
(tool-bar-mode -1)
(scroll-bar-mode -1)


;; 无边框
(add-to-list 'default-frame-alist '(undecorated . t))
(add-to-list 'initial-frame-alist '(undecorated . t))
;; (add-to-list 'default-frame-alist '(internal-border-width . 0))

;; 按像素调整窗口大小
(setq frame-resize-pixelwise t)
;; 伪全屏
(add-to-list 'default-frame-alist '(fullscreen . maximized))

(setq display-line-numbers-type 'relative)
(global-display-line-numbers-mode t)


