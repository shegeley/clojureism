(list
 (channel
  (name 'guix)
  (url "https://codeberg.org/guix/guix")
  ;; bumps guile-ares-rs to 0.9.7
  (commit "8ebc554e6acd35f2751a370e179b77dc47019795")
  (introduction
   (make-channel-introduction
    "9edb3f66fd807b096b48283debdcddccfea34bad"
    (openpgp-fingerprint
     "BBB0 2DDF 2CEA F6A8 0D1D  E643 A2A0 6DF2 A33A 54FA")))))
