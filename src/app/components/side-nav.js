(function () {
    'use strict';

    angular.module('stock')
        .directive('sideNav', function () {
            return {
                restrict: 'AC',
                link: function (scope, el) {
                    var $BODY = $('body'),
                        $MENU_TOGGLE = $('#menu_toggle'),
                        $SIDEBAR_MENU = $('#sidebar-menu'),
                        $SIDEBAR_FOOTER = $('.sidebar-footer'),
                        $LEFT_COL = $('.left_col'),
                        $RIGHT_COL = $('.right_col'),
                        $NAV_MENU = $('.nav_menu'),
                        $FOOTER = $('footer');

                    var setContentHeight = function () {
                        // reset height
                        $RIGHT_COL.css('min-height', $(window).height());

                        var bodyHeight = $BODY.outerHeight(),
                            footerHeight = $BODY.hasClass('footer_fixed') ? 0 : $FOOTER.height(),
                            leftColHeight = $LEFT_COL.eq(1).height() + $SIDEBAR_FOOTER.height(),
                            contentHeight = bodyHeight < leftColHeight ? leftColHeight : bodyHeight;

                        // normalize content
                        contentHeight -= $NAV_MENU.height() + footerHeight;

                        $RIGHT_COL.css('min-height', contentHeight);
                    };

                    var setCurrentPage = function (url) {
                        var CURRENT_URL = url || window.location.href.split('?')[0];

                        $SIDEBAR_MENU.find('li.current-page').removeClass('current-page');

                        $SIDEBAR_MENU.find('a').filter(function () {
                            return this.href == CURRENT_URL;
                        }).parent('li').addClass('current-page').parents('ul').slideDown(function () {
                            setContentHeight();
                        }).parent().addClass('active');
                    };

                    function initSideMenu (class_name) {
                        $SIDEBAR_MENU.find('a' + class_name).on('click', function (ev) {
                            var element = ev.target;
                            if (!element.href && element.parentNode instanceof HTMLAnchorElement) {
                                element = element.parentNode
                            }
                            if (element.href) {
                                setCurrentPage(element.href);
                            } else {
                                var $li = $(this).parent();

                                if ($li.is('.active')) {
                                    $li.removeClass('active active-sm');
                                    $('ul:first', $li).slideUp(function () {
                                        setContentHeight();
                                    });
                                } else {
                                    // prevent closing menu if we are on child menu
                                    if (!$li.parent().is('.child_menu')) {
                                        $SIDEBAR_MENU.find('li').removeClass('active active-sm');
                                        $SIDEBAR_MENU.find('li ul').slideUp();
                                    }

                                    $li.addClass('active');

                                    $('ul:first', $li).slideDown(function () {
                                        setContentHeight();
                                    });
                                }
                            }
                        });
                    }

                    initSideMenu('');

                    scope.$watch('app.navigation', function () {
                        initSideMenu('.dynamic_menu');
                    });

                    scope.$watch('app.admin_menu', function () {
                        initSideMenu('.admin_menu');
                    });

                    // toggle small or large menu
                    $MENU_TOGGLE.on('click', function () {
                        if ($BODY.hasClass('nav-md')) {
                            $SIDEBAR_MENU.find('li.active ul').hide();
                            $SIDEBAR_MENU.find('li.active').addClass('active-sm').removeClass('active');
                        } else {
                            $SIDEBAR_MENU.find('li.active-sm ul').show();
                            $SIDEBAR_MENU.find('li.active-sm').addClass('active').removeClass('active-sm');
                        }

                        $BODY.toggleClass('nav-md nav-sm');

                        setContentHeight();
                    });

                    setCurrentPage();

                    // recompute content when resizing
                    $(window).smartresize(function () {
                        console.log('smart_resize');
                        setContentHeight();
                    });

                    setContentHeight();

                    // fixed sidebar
                    if ($.fn.mCustomScrollbar) {
                        $('.menu_fixed').mCustomScrollbar({
                            autoHideScrollbar: true,
                            theme: 'minimal',
                            mouseWheel: {preventDefault: true}
                        });
                    }
                }
            };
        });
})();
