(setq load-prefer-newer t)
(setq inhibit-startup-screen t)

(menu-bar-mode -1)
(tool-bar-mode -1)
(scroll-bar-mode -1)


;; 无边框
(add-to-list 'default-frame-alist '(undecorated . t))
(add-to-list 'initial-frame-alist '(undecorated . t))
;; (add-to-list 'default-frame-alist '(internal-border-width . 0))

(setq display-line-numbers-type 'relative)
(global-display-line-numbers-mode t)


;; 额外保险：进入 vterm 时关闭
(add-hook 'vterm-mode-hook
          (lambda ()
            (display-line-numbers-mode 0)))

(defun my/disable-line-numbers-for-special-buffers ()
  (when (member (buffer-name) '("*Shell Command Output*" "*Async Shell Command*"))
    (display-line-numbers-mode 0)))

(add-hook 'after-change-major-mode-hook #'my/disable-line-numbers-for-special-buffers)
