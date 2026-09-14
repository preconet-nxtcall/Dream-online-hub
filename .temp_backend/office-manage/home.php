<?php 
include 'partials/_header.php';
$user_id = $_SESSION['user_id'];

$qrydisplay2 = mysqli_query($conn, "SELECT * FROM `features` WHERE type = 'BOOK' AND show_status = 'ACTIVE'") or die(mysqli_error($conn));
$rowcount2 = mysqli_num_rows($qrydisplay2);

$book_count = mysqli_query($conn, "SELECT * FROM `subscription` WHERE user_id = '$user_id' AND stage_status = 'DONE' AND show_status = 'ACTIVE'") or die(mysqli_error($conn));
$rowcount3 = mysqli_num_rows($book_count);

$rowcount4 = $rowcount2 - $rowcount3;

$qrydisplay5 = mysqli_query($conn, "SELECT IFNULL(SUM(amount),0) AS total_pending_amount FROM `recharge` WHERE user_id = '$user_id' AND (stage_status = 'AGENCY-PENDING' OR stage_status = 'AGENCY-DONE' OR stage_status = 'EMPLOYEE-PENDING')") or die(mysqli_error($conn));
$row5 = mysqli_fetch_assoc($qrydisplay5);
$rowcount5 = $row5['total_pending_amount'];

$qrydisplay6 = mysqli_query($conn, "SELECT IFNULL(SUM(amount),0) AS total_done_amount FROM `recharge` WHERE user_id = '$user_id' AND stage_status = 'EMPLOYEE-DONE'") or die(mysqli_error($conn));
$row6 = mysqli_fetch_assoc($qrydisplay6);
$rowcount6 = $row6['total_done_amount'];

$whatsapp_num = !empty($site_dls['whatsapp']) ? preg_replace('/[^0-9]/', '', $site_dls['whatsapp']) : '';
$whatsapp_url = !empty($whatsapp_num) ? 'https://api.whatsapp.com/send/?phone=' . $whatsapp_num . '&text=Hello%2C%20I%20need%20assistance' : 'https://api.whatsapp.com/send/?phone=' . htmlspecialchars($site_dls['whatsapp'] ?? '');
?>

<style>
    /* DreamHub Dark Neon Dashboard System */
    :root {
        --bg: #04111F;
        --bg-deep: #020B16;
        --surface: #071B31;
        --surface-2: #0B2440;
        --surface-3: #102D4F;
        --border: #135FA8;
        --border-soft: #1A3F66;
        --text: #F7FAFF;
        --text-2: #9FB8D9;
        --text-muted: #6E88A8;
        --cyan: #17C8FF;
        --blue: #087BFF;
        --indigo: #315BFF;
        --purple: #6C46FF;
        --success: #25E38A;
        --warning: #FFB020;
        --danger: #FF355D;
        --info: #48B9FF;

        --gradient-primary: linear-gradient(90deg, #17C8FF 0%, #087BFF 48%, #315BFF 100%);
        --gradient-secondary: linear-gradient(90deg, #087BFF 0%, #6C46FF 100%);
        --gradient-panel: linear-gradient(180deg, #0B2440 0%, #06182C 100%);
        --gradient-page: radial-gradient(circle at 70% 5%, rgba(23,200,255,.14), transparent 32%), linear-gradient(180deg, #04111F 0%, #020B16 100%);

        --radius-sm: 12px;
        --radius-md: 16px;
        --radius-lg: 22px;
        --radius-xl: 28px;
        --radius-pill: 999px;

        --shadow-card: 0 12px 40px rgba(0,0,0,.28);
        --shadow-glow: 0 0 24px rgba(23,200,255,.28);
        --shadow-button: 0 10px 30px rgba(8,123,255,.38);

        --font-ui: Inter, ui-sans-serif, system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
    }

    body, #wrapper, .main-content, .tf-container {
        background: var(--gradient-page) !important;
        background-color: var(--bg) !important;
        color: var(--text) !important;
        font-family: var(--font-ui) !important;
        min-height: 100vh;
    }

    /* Dashboard Container */
    .dh-dashboard-wrap {
        max-width: 580px;
        margin: 0 auto;
        padding: 10px 18px 10px 18px;
    }

    /* Swiper Hero Slider Container */
    .dh-hero-swiper {
        width: 100%;
        overflow: hidden;
        margin-bottom: 24px;
        position: relative;
        border-radius: var(--radius-xl);
    }

    .dh-hero-swiper .swiper-slide {
        width: 100%;
        height: auto;
    }

    /* Hero Banner Card */
    .dh-hero-card {
        background: var(--gradient-panel);
        border: 1px solid var(--border-soft);
        border-radius: var(--radius-xl);
        padding: 10px 22px 15px 22px;
        position: relative;
        overflow: hidden;
        box-shadow: var(--shadow-card);
        min-height: 210px;
        display: flex;
        flex-direction: column;
        justify-content: space-between;
    }

    .dh-hero-pagination {
        position: absolute;
        bottom: 14px !important;
        left: 22px !important;
        width: auto !important;
        display: flex;
        align-items: center;
        gap: 6px;
        z-index: 10;
    }

    .dh-hero-pagination .swiper-pagination-bullet {
        width: 8px;
        height: 8px;
        border-radius: 50%;
        background: var(--border-soft);
        opacity: 0.7;
        margin: 0 !important;
        transition: all 0.3s ease;
        cursor: pointer;
    }

    .dh-hero-pagination .swiper-pagination-bullet-active {
        width: 22px;
        border-radius: 12px;
        background: var(--cyan);
        box-shadow: 0 0 10px rgba(23, 200, 255, 0.6);
        opacity: 1;
    }


    .dh-hero-bg-img {
        position: absolute;
        right: -10px;
        bottom: -10px;
        width: 58%;
        height: 105%;
        object-fit: cover;
        object-position: right center;
        mask-image: linear-gradient(90deg, transparent 0%, rgba(0,0,0,0.85) 30%, #000 100%);
        -webkit-mask-image: linear-gradient(90deg, transparent 0%, rgba(0,0,0,0.85) 30%, #000 100%);
        pointer-events: none;
        z-index: 1;
    }

    .dh-hero-content {
        position: relative;
        z-index: 2;
        max-width: 66%;
    }

    .dh-hero-kicker {
        font-size: 10px;
        font-weight: 700;
        letter-spacing: 2px;
        color: var(--text-2);
        text-transform: uppercase;
        margin-bottom: 8px;
    }

    .dh-hero-title {
        font-size: 21px;
        font-weight: 800;
        line-height: 1.25;
        color: var(--text);
        margin-bottom: 8px;
        letter-spacing: -0.3px;
    }

    .dh-hero-title .highlight {
        color: var(--cyan);
    }

    .dh-hero-subtext {
        font-size: 12px;
        color: var(--text-2);
        line-height: 1.4;
        margin-bottom: 16px;
    }

    .dh-hero-btn {
        display: inline-flex;
        align-items: center;
        gap: 6px;
        background: var(--gradient-primary);
        color: #ffffff !important;
        font-size: 14px;
        font-weight: 700;
        padding: 10px 22px;
        border-radius: var(--radius-pill);
        text-decoration: none !important;
        box-shadow: var(--shadow-button);
        transition: all 0.25s ease;
        border: none;
    }

    .dh-hero-btn:hover {
        transform: translateY(-2px);
        box-shadow: 0 12px 32px rgba(8, 123, 255, 0.5);
    }

    .dh-hero-dots {
        display: flex;
        align-items: center;
        gap: 6px;
        margin-top: 14px;
        position: relative;
        z-index: 2;
    }

    .dh-dot {
        width: 8px;
        height: 8px;
        border-radius: 50%;
        background: var(--border-soft);
        transition: all 0.3s ease;
    }

    .dh-dot.active {
        width: 22px;
        border-radius: 12px;
        background: var(--cyan);
        box-shadow: 0 0 10px rgba(23, 200, 255, 0.6);
    }

    .dh-hero-badge-text {
        position: absolute;
        right: 18px;
        bottom: 14px;
        z-index: 2;
        font-size: 9px;
        font-weight: 700;
        letter-spacing: 1.5px;
        color: rgba(255, 255, 255, 0.5);
        text-transform: uppercase;
        text-align: right;
        pointer-events: none;
    }

    /* Section Header */
    .dh-section-header {
        display: flex;
        align-items: center;
        justify-content: space-between;
        margin-bottom: 16px;
    }

    .dh-section-title {
        font-size: 22px;
        font-weight: 800;
        color: var(--text);
        letter-spacing: -0.4px;
    }

    .dh-section-link {
        font-size: 14px;
        font-weight: 600;
        color: var(--blue);
        text-decoration: none !important;
        display: inline-flex;
        align-items: center;
        gap: 4px;
        transition: color 0.2s ease;
    }

    .dh-section-link:hover {
        color: var(--cyan);
    }

    /* Games Stack */
    .dh-games-stack {
        display: flex;
        flex-direction: column;
        gap: 14px;
        margin-bottom: 24px;
    }

    .dh-game-card {
        background: var(--surface-2);
        border: 1px solid var(--border-soft);
        border-radius: var(--radius-lg);
        padding: 7px 9px;
        display: flex;
        align-items: center;
        justify-content: space-between;
        gap: 7px;
        box-shadow: 0 6px 20px rgba(0, 0, 0, 0.2);
        transition: all 0.25s ease;
    }

    .dh-game-card:hover {
        border-color: var(--cyan);
        box-shadow: 0 8px 28px rgba(23, 200, 255, 0.18);
        transform: translateY(-2px);
    }

    .dh-game-left {
        display: flex;
        align-items: center;
        gap: 14px;
        overflow: hidden;
    }

    .dh-game-icon {
        width: 52px;
        height: 52px;
        border-radius: var(--radius-md);
        object-fit: cover;
        background: #000000;
        border: 1px solid var(--border-soft);
        flex-shrink: 0;
        display: flex;
        align-items: center;
        justify-content: center;
        overflow: hidden;
    }

    .dh-game-icon img {
        width: 100%;
        height: 100%;
        object-fit: cover;
    }

    .dh-game-info {
        display: flex;
        flex-direction: column;
        gap: 3px;
    }

    .dh-game-name {
        font-size: 16px;
        font-weight: 800;
        color: var(--text);
        letter-spacing: 0.2px;
        text-transform: uppercase;
    }

    .dh-game-category {
        font-size: 12px;
        color: var(--text-muted);
        font-weight: 500;
    }

    .dh-btn-action {
        display: inline-flex;
        align-items: center;
        gap: 6px;
        padding: 10px 20px;
        border-radius: var(--radius-pill);
        font-size: 14px;
        font-weight: 700;
        text-decoration: none !important;
        white-space: nowrap;
        border: none;
        cursor: pointer;
        transition: all 0.25s ease;
        flex-shrink: 0;
    }

    .dh-btn-open {
        background: var(--blue);
        color: #ffffff !important;
        box-shadow: 0 6px 18px rgba(8, 123, 255, 0.35);
    }

    .dh-btn-open:hover {
        background: #1d86ff;
        box-shadow: 0 8px 24px rgba(8, 123, 255, 0.5);
        transform: translateY(-1px);
    }

    .dh-btn-get {
        background: var(--gradient-primary);
        color: #ffffff !important;
        box-shadow: var(--shadow-button);
    }

    .dh-btn-get:hover {
        transform: translateY(-1px);
        filter: brightness(1.08);
    }

    /* Trust & Support Panel */
    .dh-trust-panel {
        background: var(--surface-2);
        border: 1px solid var(--border-soft);
        border-radius: var(--radius-lg);
        padding: 16px 18px;
        display: flex;
        align-items: center;
        justify-content: space-between;
        margin-bottom: 24px;
        box-shadow: 0 6px 20px rgba(0, 0, 0, 0.2);
    }

    .dh-trust-item {
        display: flex;
        align-items: center;
        gap: 10px;
        flex: 1;
    }

    .dh-trust-icon {
        width: 42px;
        height: 42px;
        border-radius: 50%;
        background: rgba(23, 200, 255, 0.12);
        color: var(--cyan);
        display: flex;
        align-items: center;
        justify-content: center;
        font-size: 20px;
        flex-shrink: 0;
    }

    .dh-trust-text {
        display: flex;
        flex-direction: column;
    }

    .dh-trust-title {
        font-size: 13px;
        font-weight: 700;
        color: var(--text);
    }

    .dh-trust-subtext {
        font-size: 10px;
        color: var(--text-muted);
    }

    .dh-trust-divider {
        width: 1px;
        height: 36px;
        background: var(--border-soft);
        margin: 0 12px;
    }

    .dh-support-item {
        display: flex;
        align-items: center;
        gap: 10px;
        text-decoration: none !important;
        color: inherit;
        flex: 1;
        justify-content: flex-end;
    }

    .dh-support-icon {
        width: 42px;
        height: 42px;
        border-radius: 50%;
        background: rgba(49, 91, 255, 0.15);
        color: var(--cyan);
        display: flex;
        align-items: center;
        justify-content: center;
        font-size: 20px;
        flex-shrink: 0;
    }

    .dh-support-text {
        display: flex;
        flex-direction: column;
    }

    .dh-support-title {
        font-size: 13px;
        font-weight: 700;
        color: var(--text);
    }

    .dh-support-subtext {
        font-size: 10px;
        color: var(--text-2);
        display: flex;
        align-items: center;
        gap: 4px;
    }

    /* Modal Overrides */
    .modal-content {
        background: var(--surface-2) !important;
        color: var(--text) !important;
        border: 1px solid var(--border-soft) !important;
        box-shadow: var(--shadow-card) !important;
        border-radius: var(--radius-xl) !important;
    }
    .modal-content input {
        background: var(--surface-3) !important;
        border: 1px solid var(--border-soft) !important;
        color: var(--text) !important;
        border-radius: var(--radius-sm) !important;
    }
</style>

<div class="dh-dashboard-wrap">

    <!-- Hero Feature Banner Slider -->
    <div class="swiper dh-hero-swiper" dir="ltr">
        <div class="swiper-wrapper">
            <?php
                $qryslide = mysqli_query($conn, "SELECT * FROM `cmstable` WHERE type = 'HOME-SLIDE' AND show_status = 'ACTIVE' ORDER BY ABS(id) DESC") or die(mysqli_error($conn));
                while($resultslide = mysqli_fetch_array($qryslide)){
                    $slide_img = !empty($resultslide['image']) ? $m_url . ADD_PHOTO_SITE_PATH . $resultslide['image'] : $m_url . 'assets/images/hero_cards.jpg';
                    $slide_name = !empty($resultslide['name']) ? $resultslide['name'] : 'Your Favourite Games, <span class="highlight">All in One Place</span>';
                    $slide_sub = !empty($resultslide['slag']) ? $resultslide['slag'] : 'Play live casino, card games and more – anytime, anywhere.';
                    $slide_btn = !empty($resultslide['title']) ? $resultslide['title'] : 'Explore Games';
                    $slide_link = !empty($resultslide['detail']) ? $resultslide['detail'] : '#games-section';
            ?>
            <div class="swiper-slide">
                <div class="dh-hero-card">
                    <img src="<?php echo htmlspecialchars($slide_img); ?>" alt="Slide Image" class="dh-hero-bg-img">
                    <div class="dh-hero-content">
                        <div class="dh-hero-kicker">PLAY &nbsp;•&nbsp; WIN &nbsp;•&nbsp; REPEAT</div>
                        <h1 class="dh-hero-title"><?php echo $slide_name; ?></h1>
                        <p class="dh-hero-subtext"><?php echo htmlspecialchars($slide_sub); ?></p>
                        <a href="<?php echo htmlspecialchars($slide_link); ?>" class="dh-hero-btn">
                            <span><?php echo htmlspecialchars($slide_btn); ?></span>
                            <i class="bi bi-chevron-right" style="font-size: 13px;"></i>
                        </a>
                    </div>
                    <div class="dh-hero-badge-text">
                        REAL GAMES<br>REAL EXCITEMENT
                    </div>
                </div>
            </div>
            <?php } ?>
        </div>
        <!-- Swiper Pagination Dots -->
        <div class="dh-hero-pagination swiper-pagination"></div>
    </div>


    <!-- Games Section -->
    <div id="games-section">
        <div class="dh-section-header">
            <h2 class="dh-section-title">Games</h2>
            
        </div>

        <div class="dh-games-stack">
            <?php                               
                $qrydisplay7 = mysqli_query($conn, "SELECT * FROM `features` WHERE type = 'BOOK' AND show_status = 'ACTIVE' ORDER BY ABS(id) DESC") or die(mysqli_error($conn));
                $all_game_modals = '';
                while($result7 = mysqli_fetch_array($qrydisplay7)){                 
                    $book_id = $result7['id'];
                    $qrys = mysqli_query($conn, "SELECT * FROM `subscription` WHERE book_id = '$book_id' AND user_id = '$user_id'") or die(mysqli_error($conn));
                    $resultidpss = mysqli_fetch_array($qrys);

                    // Dynamic fallback categories if empty
                    $categories = 'Sports  |  Casino  |  Live Games';
                    if (strpos(strtoupper($result7['name']), '444') !== false) {
                        $categories = 'Casino  |  Slots  |  Live Casino';
                    } elseif (strpos(strtoupper($result7['name']), 'LOTUS') !== false) {
                        $categories = 'Sports  |  Casino  |  Cricket';
                    }
            ?>
            <div class="dh-game-card">
                <div class="dh-game-left">
                    <div class="dh-game-icon">
                        <img src="<?php echo $m_url . ADD_PHOTO_SITE_PATH . $result7['image']; ?>" alt="<?php echo htmlspecialchars($result7['name']); ?>">
                    </div>
                    <div class="dh-game-info">
                        <div class="dh-game-name"><?php echo htmlspecialchars($result7['name']); ?></div>
                        <div class="dh-game-category"><?php echo $categories; ?></div>
                    </div>
                </div>

                <?php if (mysqli_num_rows($qrys) > 0) { ?>
                    <a data-bs-toggle="modal" data-bs-target="#modalsublink<?php echo $book_id; ?>" class="dh-btn-action dh-btn-open">
                        <span>Open Site</span>
                        <i class="bi bi-chevron-right" style="font-size: 13px;"></i>
                    </a>
                    <?php
                    ob_start();
                    ?>
                    <!-- Book Modal -->
                    <div class="modal fade form-sign-in modal-part-content" id="modalsublink<?php echo $book_id; ?>" tabindex="-1" aria-hidden="true">
                        <div class="modal-dialog modal-dialog-centered">
                            <div class="modal-content">
                                <div class="header mb-0 d-flex justify-content-between align-items-center px-4 pt-4 pb-3" style="border-bottom: 1px solid var(--border-soft);">
                                    <div class="demo-title fw-bold" style="font-size: 18px; color: var(--text);"><?php echo htmlspecialchars($result7['name']); ?></div>
                                    <span class="icon-close icon-close-popup" data-bs-dismiss="modal" style="cursor: pointer; font-size: 20px; color: var(--text);"></span>
                                </div>
                                <div class="tf-login-form p-4">
                                    <div class="w-100 mb-3">
                                        <a href="<?php echo htmlspecialchars($result7['detail']); ?>" target="_blank" class="dh-btn-action dh-btn-get w-100 text-center justify-content-center py-2" style="font-size: 15px;">
                                            Visit the website <i class="bi bi-box-arrow-up-right ms-1"></i>
                                        </a>
                                    </div>
                                    <div class="w-100 mb-3 text-start">
                                        <b class="mb-1 d-block" style="color: var(--text);">User ID :</b>
                                        <?php if (!empty($resultidpss['username'])) { ?>
                                        <div class="coupon-box d-flex align-items-center my-1 gap-2">
                                            <input type="text" value="<?php echo htmlspecialchars($resultidpss['username'], ENT_QUOTES); ?>" readonly style="padding: 8px 12px; width: 100%;">
                                            <button type="button" onclick="copyToClipboard('<?php echo addslashes($resultidpss['username']); ?>')" class="dh-btn-action dh-btn-open py-2 px-3">Copy</button>
                                        </div>
                                        <?php } else { ?>
                                            <span style="color: var(--text-muted); font-size: 13px;">Credentials Not Yet Generated</span>
                                        <?php } ?>
                                    </div>
                                    <div class="w-100 text-start">
                                        <b class="mb-1 d-block" style="color: var(--text);">Password :</b>
                                        <?php if (!empty($resultidpss['password'])) { ?>
                                        <div class="coupon-box d-flex align-items-center my-1 gap-2">
                                            <input type="text" value="<?php echo htmlspecialchars($resultidpss['password'], ENT_QUOTES); ?>" readonly style="padding: 8px 12px; width: 100%;">
                                            <button type="button" onclick="copyToClipboard('<?php echo addslashes($resultidpss['password']); ?>')" class="dh-btn-action dh-btn-open py-2 px-3">Copy</button>
                                        </div>
                                        <?php } else { ?>
                                            <span style="color: var(--text-muted); font-size: 13px;">Credentials Not Yet Generated</span>
                                        <?php } ?>
                                    </div>
                                </div>
                            </div>
                        </div>
                    </div>
                    <!-- /Book Modal -->
                    <?php
                    $all_game_modals .= ob_get_clean();
                    ?>
                <?php } else { ?>
                    <input type="hidden" class="book_id" value="<?php echo $result7['id']; ?>">
                    <a href="javascript:void(0)" class="add_subscribe_ajax dh-btn-action dh-btn-get">
                        <span>Get ID</span>
                        <i class="bi bi-chevron-right" style="font-size: 13px;"></i>
                    </a>
                <?php } ?>
            </div>
            <?php } ?>
        </div>
    </div>

    <!-- Safe • Secure • Trusted & 24/7 Support Panel -->
    <div class="dh-trust-panel">
        <div class="dh-trust-item">
            <div class="dh-trust-icon">
                <i class="bi bi-shield-check"></i>
            </div>
            <div class="dh-trust-text">
                <div class="dh-trust-title">Safe • Secure • Trusted</div>
                <div class="dh-trust-subtext">Your gaming experience, our priority.</div>
            </div>
        </div>

        <div class="dh-trust-divider"></div>

        <a href="<?php echo htmlspecialchars($whatsapp_url); ?>" target="_blank" class="dh-support-item">
            <div class="dh-support-icon">
                <i class="bi bi-people-fill"></i>
            </div>
            <div class="dh-support-text">
                <div class="dh-support-title">24/7</div>
                <div class="dh-support-subtext">
                    <span>Customer Support</span>
                    <i class="bi bi-chevron-right" style="font-size: 10px;"></i>
                </div>
            </div>
        </a>
    </div>

</div>

<!-- Render all Game Modals -->
<?php echo $all_game_modals; ?>

<script>
    function copyToClipboard(text) {
        if (!text) return;

        function showSwalSuccess() {
            swal({
                title: "Copied!",
                text: text + " copied to clipboard",
                icon: "success",
                timer: 2000,
                buttons: false
            });
        }

        if (navigator.clipboard && window.isSecureContext) {
            navigator.clipboard.writeText(text).then(function() {
                showSwalSuccess();
            }).catch(function() {
                fallbackCopyText(text, showSwalSuccess);
            });
        } else {
            fallbackCopyText(text, showSwalSuccess);
        }
    }

    function fallbackCopyText(text, callback) {
        var textArea = document.createElement("textarea");
        textArea.value = text;
        textArea.style.top = "0";
        textArea.style.left = "0";
        textArea.style.position = "fixed";
        textArea.style.opacity = "0";
        document.body.appendChild(textArea);
        textArea.focus();
        textArea.select();
        try {
            var successful = document.execCommand('copy');
            if (successful) {
                callback();
            } else {
                swal("Error", "Unable to copy text", "error");
            }
        } catch (err) {
            swal("Error", "Unable to copy text", "error");
        }
        document.body.removeChild(textArea);
    }
</script>

<?php
if (!empty($_SESSION['swl_type']) && $_SESSION['swl_type'] != '') {
?>
    <script>
        window.addEventListener('load', function() {
            swal({
                title: "<?php echo $_SESSION['head']; ?>",
                text: "<?php echo $_SESSION['text']; ?>",
                icon: "<?php echo $_SESSION['swl_type']; ?>",
                button: "Ok Done!",
                showConfirmButton: false,
                timer: 5000
            }).then(function() {
                location.reload();
            });
        });
    </script>
<?php
    unset($_SESSION['head']);
    unset($_SESSION['text']);
    unset($_SESSION['swl_type']);
}
?>

<script>
    // Initialize Hero Swiper Slider
    document.addEventListener('DOMContentLoaded', function() {
        if (typeof Swiper !== 'undefined') {
            new Swiper('.dh-hero-swiper', {
                slidesPerView: 1,
                spaceBetween: 0,
                loop: true,
                autoplay: {
                    delay: 3500,
                    disableOnInteraction: false,
                },
                pagination: {
                    el: '.dh-hero-pagination',
                    clickable: true,
                },
                speed: 800
            });
        }
    });
</script>

<?php include 'partials/_footer.php'; ?>