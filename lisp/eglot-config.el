;;; eglot-config.el -*- lexical-binding: t; -*-
;; 让 .rs 文件使用内置 rust-ts-mode
(add-to-list 'auto-mode-alist '("\\.rs\\'" . rust-ts-mode))

(use-package eglot
  :ensure t
  :hook ((rust-ts-mode . eglot-ensure)
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

;; lombok
(defun get-lombok-jar ()
  (getenv "LOMBOK_JAR"))


(use-package eglot-java
  :ensure t
    ;; `eglot-java-mode' installs the `jdt://' handler and asks jdtls for
  ;; `java/classFileContents', which is required for `M-.' into dependency classes.
  :hook ((java-mode . eglot-java-mode)
         (java-ts-mode . eglot-java-mode))
  :config
  (setq eglot-java-elipse-jdt-args (let ((lombok (get-lombok-jar)))
                                     (append (when lombok
                                               (list (concat "-javaagent:" lombok)))
                                             '("-Xmx8G"
                                               "-XX:+UseZGC"
                                               )
                                             ))))

(setq eglot-java-user-init-opts-fn 'custom-eglot-java-init-opts)
(defun custom-eglot-java-init-opts (server eglot-java-eclipse-jdt)
  "Custom options that will be merged with any default settings."
  (ignore server eglot-java-eclipse-jdt)
  `(:settings
    (:java
     (:format
      (:settings
       (:indentSize 4
        :tabSize 4
        :insertSpaces t))
      :autobuild
      (:enabled t)
      :maxConcurrentBuilds 8
      :home ,(getenv "JAVA_HOME")
      :project
      (:encoding "UTF-8")
      :foldingRange
      (:enabled t)
      :selectionRange
      (:enabled t)
      :import
      (:gradle
       (:enabled t))
      :inlayhints
      (:parameterNames
       (:enabled "ALL"))
      :referenceCodeLens
      (:enabled t)
      :implementationsCodeLens
      (:enabled t)
      :templates
      (:typeComment
       ["/**"
        " * ${type_name}."
        " *"
        " * @author ${user}"
        " */"])
      :eclipse
      (:downloadSources t)
      :maven
      (:downloadSources t
       :updateSnapshots t)
      :signatureHelp
      (:enabled t
       :description
       (:enabled t))
      :contentProvider
      (:preferred "fernflower")
      :completion
      (:favoriteStaticMembers ["org.junit.Assert.*"
                               "org.junit.Assume.*"
                               "org.junit.jupiter.api.Assertions.*"
                               "org.junit.jupiter.api.Assumptions.*"
                               "org.junit.jupiter.api.DynamicContainer.*"
                               "org.junit.jupiter.api.DynamicTest.*"
                               "org.assertj.core.api.Assertions.assertThat"
                               "org.assertj.core.api.Assertions.assertThatThrownBy"
                               "org.assertj.core.api.Assertions.assertThatExceptionOfType"
                               "org.assertj.core.api.Assertions.catchThrowable"
                               "java.util.Objects.requireNonNull"
                               "java.util.Objects.requireNonNullElse"
                               "org.mockito.Mockito.*"]
       :filteredTypes ["com.sun.*"
                       "io.micrometer.shaded.*"
                       "java.awt.*"
                       "org.graalvm.*"
                       "jdk.*"
                       "sun.*"]
       :importOrder ["java" "javax" "org" "com"])
      :sources
      (:organizeImports
       (:starThreshold 9999
        :staticStarThreshold 9999))
      :saveActions
      (:organizeImports t)
      :configuration
      (:maven
       (:userSettings ,(maven-user-settings)
        :globalSettings ,(maven-global-settings)))))))

;; 定义一个函数来获取 Maven 的用户设置路径
;; 读取 MAVEN_SETTINGS_XML 环境变量，如果没有设置，则使用默认路径
(defun maven-user-settings ()
  "Return the path to the Maven user settings.xml file."
  (or (getenv "MAVEN_SETTINGS_XML")
      (expand-file-name "~/.m2/settings.xml")))

(defun maven-global-settings ()
  "Return the path to the Maven global settings.xml file, or nil."
  (let* ((maven-home (or (getenv "M2_HOME")
                         (getenv "MAVEN_HOME")
                         (let ((m2-bin (getenv "M2")))
                           (when m2-bin
                             (directory-file-name
                              (expand-file-name ".." m2-bin))))))
         (settings-file
          (when maven-home
            (expand-file-name "conf/settings.xml" maven-home))))
    (when (and settings-file (file-readable-p settings-file))
      settings-file)))


(provide 'eglot-config)
