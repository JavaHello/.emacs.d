;;; init.el -*- lexical-binding: t; -*-

;; 配置字符集
(set-terminal-coding-system 'utf-8)
(set-keyboard-coding-system 'utf-8)
(prefer-coding-system 'utf-8)

(setq custom-file "~/.emacs.custom.el")
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



(load-theme 'gruvbox-dark-medium t)

(require 'package)

(setq package-archives '(("melpa" . "https://melpa.org/packages/")
                         ("gnu"   . "https://elpa.gnu.org/packages/")))

(package-initialize)




(add-to-list 'load-path "~/.emacs.d/simpc-mode")
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
  :hook (prog-mode . diff-hl-mode))

(use-package markdown-mode
  :ensure t
  :mode ("\\.md\\'" . markdown-mode))
  ;; :init
;;  (setq markdown-command "pandoc"))
(setq markdown-fontify-code-blocks-natively t)
(setq markdown-enable-math t)
(setq markdown-hide-urls nil)


;; 其他配置
;; 额外保险：进入 vterm 时关闭
(add-hook 'vterm-mode-hook
          (lambda ()
            (display-line-numbers-mode 0)))

(defun my/disable-line-numbers-for-special-buffers ()
  (when (member (buffer-name) '("*Shell Command Output*" "*Async Shell Command*"))
    (display-line-numbers-mode 0)))

(add-hook 'after-change-major-mode-hook #'my/disable-line-numbers-for-special-buffers)

;; codex config
(defconst codex-buffer-name "*codex*"
  "Shared buffer name for Codex interaction and async output.")

(defun codex--project-root ()
  "Return the current project root, or signal a user-facing error."
  (if-let ((project (project-current nil)))
      (project-root project)
    (user-error "Codex 必须在项目目录下启动")))

(defun codex--buffer ()
  "Return the shared Codex buffer."
  (get-buffer-create codex-buffer-name))

(defun codex--display-buffer ()
  "Display the shared Codex buffer."
  (display-buffer (codex--buffer)))

(defun codex--append-output (text)
  "Append TEXT to the shared Codex buffer."
  (when (and text (not (string-empty-p text)))
    (with-current-buffer (codex--buffer)
      (let ((inhibit-read-only t)
            (moving (= (point) (point-max))))
        (save-excursion
          (goto-char (point-max))
          (insert text))
        (when moving
          (goto-char (point-max)))))))

(defun codex ()
  "Open Codex CLI in a project-root vterm buffer."
  (interactive)
  (let ((default-directory (file-name-as-directory (codex--project-root))))
    (vterm codex-buffer-name)
    (vterm-send-string "codex")
    (vterm-send-return)))

(defun codex-here ()
  "Open Codex CLI from the current project root."
  (interactive)
  (codex))

(defun codex-edit-region (start end instruction)
  "Asynchronously send selected region to `codex exec` and stream output."
  (interactive "r\nsInstruction: ")
  (let* ((text (buffer-substring-no-properties start end))
         (prompt (format "%s\n\n```text\n%s\n```" instruction text))
         (default-directory (file-name-as-directory (codex--project-root)))
         (proc
          (make-process
           :name (generate-new-buffer-name "codex-edit-region")
           :buffer nil
           :command '("sh" "-lc" "codex exec - 2>&1")
           :connection-type 'pipe
           :coding 'utf-8-unix
           :noquery t
           :filter
           (lambda (_process chunk)
             (codex--append-output chunk))
           :sentinel
           (lambda (process event)
             (when (memq (process-status process) '(exit signal))
               (let ((code (process-exit-status process)))
                 (codex--append-output
                  (format "\n[codex exit %s] %s"
                          code
                          (string-trim event)))
                 (unless (zerop code)
                   (message "codex exec failed: %s (%s)"
                            code (string-trim event)))))))))
    (codex--append-output
     (format "\n\n[%s] codex exec started in %s\n"
             (format-time-string "%F %T")
             default-directory))
    (codex--display-buffer)
    (process-send-string proc prompt)
    (process-send-eof proc)
    (message "codex exec started...")))

;; keymap
(global-set-key (kbd "M-RET") 'toggle-frame-fullscreen)
