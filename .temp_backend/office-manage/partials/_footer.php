        <!-- Footer -->
        <style>
            .section-header-title {
                font-size: 20px !important;
                font-weight: 700 !important;
                color: var(--theme-text) !important;
                letter-spacing: 0.5px !important;
                margin-bottom: 0;
            }

            .section-header-row {
                display: flex;
                align-items: center;
                justify-content: space-between;
                margin-bottom: 16px;
            }

            .footer-glass-container {
                max-width: 1240px;
                margin: 0 auto 90px auto;
                padding: 0 15px;
            }

            .contact-glass-card {
                background: var(--theme-card) !important;
                backdrop-filter: blur(15px);
                -webkit-backdrop-filter: blur(15px);
                border: 1px solid var(--theme-border);
                border-radius: 20px;
                padding: 24px;
                margin-bottom: 20px;
                box-shadow: var(--theme-shadow);
            }

            .contact-input-field {
                background: var(--theme-input-bg) !important;
                border: 1px solid var(--theme-input-border) !important;
                border-radius: 10px !important;
                padding: 12px 16px !important;
                color: var(--theme-input-text) !important;
                width: 100% !important;
                font-size: 14px !important;
                outline: none !important;
                transition: border-color 0.2s ease;
            }

            .contact-input-field:focus {
                border-color: var(--theme-primary) !important;
                box-shadow: 0 0 0 3px var(--theme-glow) !important;
            }

            .contact-input-field::placeholder {
                color: var(--theme-text-muted) !important;
            }

            .contact-submit-btn {
                background: var(--theme-primary-gradient) !important;
                color: #ffffff !important;
                font-size: 15px !important;
                font-weight: 600 !important;
                padding: 14px !important;
                border-radius: 12px !important;
                border: none !important;
                width: 100% !important;
                box-shadow: 0 4px 20px var(--theme-glow) !important;
                cursor: pointer;
                transition: transform 0.2s ease, box-shadow 0.2s ease;
            }

            .contact-submit-btn:hover {
                transform: translateY(-2px);
                box-shadow: 0 6px 24px var(--theme-glow-strong) !important;
            }

            .footer-info-card {
                background: var(--theme-card) !important;
                backdrop-filter: blur(16px);
                border: 1px solid var(--theme-border) !important;
                border-radius: 20px !important;
                padding: 24px;
                display: flex;
                align-items: center;
                gap: 24px;
                box-shadow: var(--theme-shadow);
            }

            @media (max-width: 768px) {
                .footer-info-card {
                    flex-direction: column;
                    text-align: center;
                }
            }

            .game-toolbar-bottom {
                position: fixed !important;
                bottom: 0 !important;
                left: 0 !important;
                right: 0 !important;
                z-index: 1000 !important;
                background: #04111F !important;
                backdrop-filter: blur(20px);
                -webkit-backdrop-filter: blur(20px);
                border-top-left-radius: 28px !important;
                border-top-right-radius: 28px !important;
                box-shadow: 0 -4px 30px rgba(0, 0, 0, 0.4) !important;
                border: 1px solid #1A3F66 !important;
                border-bottom: none !important;
                padding: 6px 0 10px 0 !important;
            }

            .game-toolbar-item {
                display: flex;
                flex-direction: column;
                align-items: center;
                justify-content: center;
                color: #6E88A8;
                text-decoration: none !important;
                font-size: 11px;
                font-weight: 600;
                transition: all 0.3s ease;
                margin: 0 auto;
                width: 100%;
            }

            .game-toolbar-item i {
                width: 42px;
                height: 42px;
                border-radius: 50%;
                background: transparent;
                display: flex;
                align-items: center;
                justify-content: center;
                font-size: 18px;
                margin-bottom: 4px;
                color: #6E88A8;
                transition: all 0.3s ease;
                border: 1px solid transparent;
            }

            .game-toolbar-item.active i {
                background: linear-gradient(90deg, #17C8FF 0%, #087BFF 48%, #315BFF 100%) !important;
                color: #ffffff !important;
                box-shadow: 0 0 20px rgba(23, 200, 255, 0.45) !important;
                border-color: transparent !important;
            }

            .game-toolbar-item.active span {
                color: #17C8FF !important;
                font-weight: 700;
                line-height: 12px;
            }


            /* Remove lines/borders under mobile menu items */
            .nav-ul-mb, .nav-ul-mb li, .nav-mb-item {
                border: none !important;
                border-bottom: none !important;
                outline: none !important;
            }

            .mb-menu-link {
                border: none !important;
                border-bottom: none !important;
            }
        </style>

        <footer id="footer" class="footer-glass-container">
            <!-- Get in Touch Form Card (Commented Out) -->
            <?php /*
            <div class="contact-glass-card">
                <h3 class="section-header-title mb-4">Get in Touch</h3>
                <form class="form-contact" method="POST" action="<?php echo $m_url; ?><?php echo $routey;?>">
                    <div class="row g-3 mb-3">
                        <div class="col-12 col-md-6">
                            <input type="text" name="name" required placeholder="Name *" class="contact-input-field" />
                        </div>
                        <div class="col-12 col-md-6">
                            <input type="email" name="email" required placeholder="Email *" class="contact-input-field" />
                        </div>
                    </div>
                    <div class="row g-3 mb-3">
                        <div class="col-12 col-md-6">
                            <input type="number" name="phone" required placeholder="Phone *" class="contact-input-field" />
                        </div>
                        <div class="col-12 col-md-6">
                            <input type="text" name="sub" required placeholder="Subject *" class="contact-input-field" />
                        </div>
                    </div>
                    <div class="mb-4">
                        <textarea placeholder="Message" name="msg" required rows="4" class="contact-input-field"></textarea>
                    </div>
                    <div>
                        <button type="submit" name="add_contact" class="contact-submit-btn">Send</button>
                    </div>
                </form>
            </div>
            */ ?>

            <!-- Footer Logo and Tagline Card -->
            <div class="footer-info-card">
                <div style="flex-shrink: 0; max-width: 200px;">
                    <a href="<?php echo $m_url; ?>home">
                        <img src="<?php echo $m_url.ADD_PHOTO_SITE_PATH.$site_dls['white_logo']; ?>" alt="Logo" style="max-height: 48px; width: auto;">
                    </a>
                </div>
                <div style="color: #94a3b8; font-size: 13px; line-height: 1.6;">
                    <?php echo $site_dls['tag_line']; ?>
                </div>
            </div>
            
            <div class="text-center mt-3" style="color: #64748b; font-size: 12px;">
                © <script> document.write(new Date().getFullYear()) </script> <?php echo $site_dls['heading']; ?>. All Rights Reserved
            </div>
        </footer>
        <!-- /Footer -->

    </div>

    <!-- toolbar-bottom -->
    <div class="game-toolbar-bottom">
        <div class="container" style="max-width: 540px;">
            <div class="row text-center align-items-center g-0">
                <div class="col-3">
                    <a href="<?php echo $m_url; ?>home.php" class="game-toolbar-item <?php if($routerx=='/' || $routerx=='/home' || $routerx=='/home.php'){ echo "active"; }?>">
                        <i class="bi bi-house-door-fill"></i>
                        <span>Dashboard</span>
                    </a>
                </div>
                <div class="col-3">
                    <a href="<?php echo $m_url; ?>recharge.php" class="game-toolbar-item <?php if($routerx=='/recharge' || $routerx=='/recharge.php'){ echo "active"; }?>">
                        <i class="bi bi-lightning-charge-fill"></i>
                        <span>Recharge</span>
                    </a>
                </div>
                <div class="col-3">
                    <a href="<?php echo $m_url; ?>withdraw.php" class="game-toolbar-item <?php if($routerx=='/withdraw' || $routerx=='/withdraw.php'){ echo "active"; }?>">
                        <i class="bi bi-gift-fill"></i>
                        <span>Withdraw</span>
                    </a>
                </div>
                <div class="col-3">
                    <a href="<?php echo $m_url; ?>records.php" class="game-toolbar-item <?php if($routerx=='/records' || $routerx=='/records.php'){ echo "active"; }?>">
                        <i class="bi bi-journal-text"></i>
                        <span>Records</span>
                    </a>
                </div>
            </div>
        </div>
    </div>
    <!-- /toolbar-bottom -->

    <!-- sidebar account-->
    <div class="offcanvas offcanvas-start canvas-filter canvas-sidebar canvas-sidebar-account" id="mbAccount">
        <div class="canvas-wrapper">
            <header class="canvas-header">
                <span class="title">SIDEBAR ACCOUNT</span>
                <span class="icon-close icon-close-popup" data-bs-dismiss="offcanvas" aria-label="Close"></span>
            </header>
            <div class="canvas-body sidebar-mobile-append"> </div>
        </div>
    </div>
    <!-- End sidebar account -->

    <!-- Javascript -->
    <script src="<?php echo $m_url;?>assets/js/bootstrap.min.js"></script>
    <script src="<?php echo $m_url;?>assets/js/jquery.min.js"></script>
    <script src="<?php echo $m_url;?>assets/js/swiper-bundle.min.js"></script>
    <script src="<?php echo $m_url;?>assets/js/carousel.js"></script>
    <script src="<?php echo $m_url;?>assets/js/bootstrap-select.min.js"></script>
    <script src="<?php echo $m_url;?>assets/js/drift.min.js"></script>
    <script src="<?php echo $m_url;?>assets/js/lazysize.min.js"></script>
    <script src="<?php echo $m_url;?>assets/js/count-down.js"></script>
    <script src="<?php echo $m_url;?>assets/js/wow.min.js"></script>
    <script src="<?php echo $m_url;?>assets/js/nouislider.min.js"></script>
    <script src="<?php echo $m_url;?>assets/js/shop.js"></script>
    <script src="<?php echo $m_url;?>assets/js/multiple-modal.js"></script>
    <script src="<?php echo $m_url;?>assets/js/main.js"></script>
    <script src="<?php echo $m_url;?>assets/js/photoswipe-lightbox.umd.min.js"></script>
    <script src="<?php echo $m_url;?>assets/js/photoswipe.umd.min.js"></script>
    <script src="<?php echo $m_url;?>assets/js/zoom.js"></script>

    <script>
        $(document).ready(function () {
        $('.logout_btn_ajax').click(function(e){
            e.preventDefault();
            
            swal({
                title: "Are you sure ?",
                text: "If You Press Ok Then You're LOG OUT !",
                icon: "warning",
                buttons: true,
                dangerMode: true,
            })
            .then((willDelete) => {
                if (willDelete) {
                $.ajax({
                    type: "POST",
                    url: "<?php echo $m_url; ?>partials/logout.php",
                    data: {
                    },
                    success: function (response) {
                    swal("LOG OUT Done Successfully!",{
                        icon: "success",
                    }).then((result) =>{
                        window.location.replace("<?php echo $m_url; ?>");
                    });
                    }
                })
                } 
            });
        });
        });
    </script>

    <script>
        $(document).ready(function () {
        $('.add_subscribe_ajax').click(function(e){
            e.preventDefault();
            var book_id = $(this).closest("div").find('.book_id').val();           
            swal({
                title: "Subscribe ?",
                text: "If You Press Ok Then You're Subscribed !",
                icon: "info",
                buttons: true,
                dangerMode: true,
            })
            .then((willDelete) => {
                if (willDelete) {
                $.ajax({
                    type: "POST",
                    url: "<?php echo $m_url; ?>ajax.php",
                    data: {
                        "add_subscribe": 1,
                        "book_id": book_id,
                    },
                    success: function (response) {
                    swal("Subscribed Successfully!",{
                        icon: "success",
                    }).then((result) =>{
                        window.location.replace("<?php echo $m_url; ?>home");
                    });
                    }
                })
                } 
            });
        });
        });
    </script>

    <?php if(isset($_SESSION['register_show']) && $_SESSION['register_show'] == true){ ?>
    <script>
        window.addEventListener('load',function(){
            var myModal = new bootstrap.Modal(document.getElementById('login'));
            myModal.show();
        });
    </script>
    <?php } if(empty($_SESSION['swl_type'])){ unset($_SESSION['register_show']); } ?>

    <!-- Embedded Chat Widget for User Dashboard -->
    <script src="<?php echo $m_url; ?>chat/socket.io/socket.io.js"></script>
    <script src="<?php echo $m_url; ?>chat/view/chat-widget.js?v=<?php echo time(); ?>"></script>

</body>

</html>