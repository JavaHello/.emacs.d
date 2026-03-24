;;; init.el -*- lexical-binding: t; -*-

(setq custom-file "~/.emacs.custom.el")
;; 启用语法高亮
(global-font-lock-mode 1)
;; 高亮当前行
(global-hl-line-mode 1)

(set-face-attribute 'default nil
		    :font "CaskaydiaMono Nerd Font Mono-13")
;; 设置中文字体
(set-fontset-font t 'han "Noto Sans CJK SC")
(set-fontset-font t 'cjk-misc "Noto Sans CJK SC")
(set-fontset-font t 'kana "Noto Sans CJK SC")

(load-theme 'gruvbox-dark-medium t)

(require 'package)

(setq package-archives '(("melpa" . "https://melpa.org/packages/")
                         ("gnu"   . "https://elpa.gnu.org/packages/")))

(package-initialize)




(add-to-list 'load-path "~/.emacs.d/simpc-mode")
(require 'simpc-mode)
;; Automatically enabling simpc-mode on files with extensions like .h, .c, .cpp, .hpp
(add-to-list 'auto-mode-alist '("\\.[hc]\\(pp\\)?\\'" . simpc-mode))


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
(require 'server)
(unless (server-running-p)
  (server-start))
