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




