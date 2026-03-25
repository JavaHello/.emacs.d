;;; init.el -*- lexical-binding: t; -*-

;; 配置字符集
(set-terminal-coding-system 'utf-8)
(set-keyboard-coding-system 'utf-8)
(prefer-coding-system 'utf-8)

(setq custom-file (locate-user-emacs-file "custom.el"))
(when (file-readable-p custom-file)
  (load custom-file nil 'nomessage))
;; 启用语法高亮
(global-font-lock-mode 1)
;; 高亮当前行
(global-hl-line-mode 1)


;; mac meta
(when (eq system-type 'darwin) ;; mac specific settings
  (setq mac-option-modifier 'alt)
  (setq mac-command-modifier 'meta)
  (global-set-key [kp-delete] 'delete-char) ;; sets fn-delete to be right-delete
  )


;; (global-tab-line-mode t); 顶部显示 tab
(global-auto-revert-mode t) ; 外部程序修改文件自动刷新


(column-number-mode t) ; 启用列号显示
(electric-pair-mode t) ; 自动补全括号
(size-indication-mode t) ; 显示缓冲区大小
(global-hl-line-mode t) ; 高亮显示当前行


;; 判断是 gui 设置字体
(when (display-graphic-p)
  ;; 英文字体
  (pcase system-type
    ('darwin
     (set-face-attribute 'default nil :font "CaskaydiaMono Nerd Font Mono-14")
     (set-fontset-font t 'han "PingFang SC")
     (set-fontset-font t 'cjk-misc "PingFang SC")
     (set-fontset-font t 'kana "PingFang SC"))

    ('gnu/linux
     (set-face-attribute 'default nil :font "CaskaydiaMono Nerd Font Mono-13")
     (set-fontset-font t 'han "Noto Sans Mono CJK SC")
     (set-fontset-font t 'cjk-misc "Noto Sans Mono CJK SC")
     (set-fontset-font t 'kana "Noto Sans Mono CJK SC"))

    ('windows-nt
     (set-face-attribute 'default nil :font "CaskaydiaMono Nerd Font Mono-13")
     (set-fontset-font t 'han "Microsoft YaHei UI")
     (set-fontset-font t 'cjk-misc "Microsoft YaHei UI")
     (set-fontset-font t 'kana "Microsoft YaHei UI"))))




(require 'package)

(setq package-archives '(("melpa" . "https://melpa.org/packages/")
                         ("gnu"   . "https://elpa.gnu.org/packages/")))

(package-initialize)

;; 主题
(use-package gruvbox-theme
  :ensure t
  :config
  (load-theme 'gruvbox-dark-medium t))


(add-to-list 'load-path (expand-file-name "simpc-mode" user-emacs-directory))
(require 'simpc-mode)
;; Automatically enabling simpc-mode on files with extensions like .h, .c, .cpp, .hpp
(add-to-list 'auto-mode-alist '("\\.[hc]\\(pp\\)?\\'" . simpc-mode))

(require 'eglot)
;; 让 .rs 文件使用内置 rust-ts-mode
(add-to-list 'auto-mode-alist '("\\.rs\\'" . rust-ts-mode))

;; 打开 Rust 文件时自动启动内置 Eglot
(add-hook 'rust-ts-mode-hook #'eglot-ensure)

;; 如果 Emacs 找不到 rust-analyzer，可显式指定
(with-eval-after-load 'eglot
  (add-to-list 'eglot-server-programs
               '((rust-ts-mode) . ("rust-analyzer"))))

;; 默认启动 server 模式，git 提交填消息时会使用
(setenv "GIT_EDITOR" "emacsclient")
(require 'vc)
(require 'server)
(unless (server-running-p)
  (server-start))

(require 'org-tempo)


(add-hook 'org-mode-hook
  (lambda ()
    (setq-local electric-pair-inhibit-predicate
                (lambda (c)
                  (if (char-equal c ?<) t
                    (electric-pair-default-inhibit c))))))
;; 第三方 plugin
;; (require 'diff-hl)
;; (global-diff-hl-mode)


(use-package diff-hl
  :hook ((prog-mode . diff-hl-mode)
         (vc-dir-mode . diff-hl-dir-mode)
         (dired-mode . diff-hl-dired-mode))
  :config
  ;; 编辑时实时更新
  (diff-hl-flydiff-mode 1)

  ;; 和 Magit 联动：Magit 刷新后刷新 diff-hl
  (add-hook 'magit-post-refresh-hook #'diff-hl-magit-post-refresh))

(use-package markdown-mode
  :ensure t
  :mode ("\\.md\\'" . markdown-mode))
  ;; :init
;;  (setq markdown-command "pandoc"))
(setq markdown-fontify-code-blocks-natively t)
(setq markdown-enable-math t)
(setq markdown-hide-urls nil)

(use-package magit
  :ensure t
  :commands (magit-status)
  :bind ("C-x g" . magit-status))

;; 其他配置
;; 额外保险：进入 vterm 时关闭
(add-hook 'vterm-mode-hook
          (lambda ()
            (display-line-numbers-mode 0)))

(defun my/disable-line-numbers-for-special-buffers ()
  (when (member (buffer-name) '("*Shell Command Output*" "*Async Shell Command*"))
    (display-line-numbers-mode 0)))

(add-hook 'after-change-major-mode-hook #'my/disable-line-numbers-for-special-buffers)

(load (expand-file-name "codex.el" user-emacs-directory) nil t)

;; keymap
(global-set-key (kbd "M-RET") 'toggle-frame-fullscreen)
