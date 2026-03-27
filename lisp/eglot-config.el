;;; eglot-config.el -*- lexical-binding: t; -*-
;; 让 .rs 文件使用内置 rust-ts-mode
(add-to-list 'auto-mode-alist '("\\.rs\\'" . rust-ts-mode))

(use-package eglot
  :ensure t
  :hook ((java-ts-mode . eglot-ensure)
         (rust-ts-mode . eglot-ensure)
         (c++-mode . eglot-ensure))
  :config
  (add-to-list 'eglot-server-programs
               '((simpc-mode) . ("clangd")))
  (add-to-list 'eglot-server-programs
               '((zig-ts-mode) . ("zls")))
  (add-to-list 'eglot-server-programs
               '((rust-ts-mode) . ("rust-analyzer"))))

(use-package zig-mode
  :ensure t
  :mode ("\\.\\(zig\\|zon\\)\\'" . zig-mode)
  :hook (zig-mode . eglot-ensure))

(with-eval-after-load 'eglot
  (add-to-list 'eglot-server-programs
               '((rust-ts-mode) . ("rust-analyzer"))))

(provide 'eglot-config)
