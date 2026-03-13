(menu-bar-mode -1)
(tool-bar-mode -1)
(scroll-bar-mode -1)


;; 无边框
(add-to-list 'default-frame-alist '(undecorated . t))
(add-to-list 'initial-frame-alist '(undecorated . t))
;; (add-to-list 'default-frame-alist '(internal-border-width . 0))

(setq display-line-numbers-type 'relative)
(defvar display-line-numbers-exempt-modes nil)
;; 这些模式不要显示行号
(dolist (mode '(term-mode
                vterm-mode
                shell-mode
                eshell-mode
                special-mode
                shell-command-mode))
  (add-to-list 'display-line-numbers-exempt-modes mode))

(global-display-line-numbers-mode t)

(defun my/disable-line-numbers ()
  (setq-local display-line-numbers nil))

(add-hook 'vterm-mode-hook #'my/disable-line-numbers)
(add-hook 'shell-command-mode-hook #'my/disable-line-numbers)
(add-hook 'special-mode-hook #'my/disable-line-numbers)
