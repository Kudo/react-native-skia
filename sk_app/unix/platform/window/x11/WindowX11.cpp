/*
* Copyright 2016 Google Inc.
* Copyright (C) 1994-2021 OpenTV, Inc. and Nagravision S.A.
*
* Use of this source code is governed by a BSD-style license that can be
* found in the LICENSE file.
*/


#include "src/utils/SkUTF.h"
#ifdef SKA_HAS_GPU_SUPPORT
#include "GLWindowContext.h"
#endif
#include "WindowX11.h"
#include "WindowContextFactory.h"

#include "x11/PlatformDisplayX11.h"

extern "C" {
    #include "keysym2ucs.h"
}
#include <X11/Xutil.h>
#include <X11/XKBlib.h>

namespace sk_app {

SkTDynamicHash<WindowX11, XWindow> WindowX11::gWindowMap;
const long kEventMask = ExposureMask | StructureNotifyMask |
                        KeyPressMask | KeyReleaseMask |
                        PointerMotionMask | ButtonPressMask | ButtonReleaseMask;

bool WindowX11::initWindow(PlatformDisplay *platformDisplay) {

    Display* display = (dynamic_cast<PlatformDisplayX11*>(platformDisplay))->native();

    if (fRequestedDisplayParams.fMSAASampleCount != fMSAASampleCount) {
        this->closeWindow();
    }
    // we already have a window
    if (fDisplay) {
        return true;
    }
    fDisplay = display;
    fPlatformDisplay = platformDisplay;

    constexpr int initialWidth = 1280;
    constexpr int initialHeight = 960;

#if USE(GLX)
    // Attempt to create a window that supports GL

    // We prefer the more recent glXChooseFBConfig but fall back to glXChooseVisual. They have
    // slight differences in how attributes are specified.
    static int constexpr kChooseFBConfigAtt[] = {
        GLX_RENDER_TYPE, GLX_RGBA_BIT,
        GLX_DOUBLEBUFFER, True,
        GLX_STENCIL_SIZE, 8,
        None
    };
    // For some reason glXChooseVisual takes a non-const pointer to the attributes.
    int chooseVisualAtt[] = {
        GLX_RGBA,
        GLX_DOUBLEBUFFER,
        GLX_STENCIL_SIZE, 8,
        None
    };
    SkASSERT(nullptr == fVisualInfo);
    if (fRequestedDisplayParams.fMSAASampleCount > 1) {
        static const GLint kChooseFBConifgAttCnt = SK_ARRAY_COUNT(kChooseFBConfigAtt);
        GLint msaaChooseFBConfigAtt[kChooseFBConifgAttCnt + 4];
        memcpy(msaaChooseFBConfigAtt, kChooseFBConfigAtt, sizeof(kChooseFBConfigAtt));
        SkASSERT(None == msaaChooseFBConfigAtt[kChooseFBConifgAttCnt - 1]);
        msaaChooseFBConfigAtt[kChooseFBConifgAttCnt - 1] = GLX_SAMPLE_BUFFERS_ARB;
        msaaChooseFBConfigAtt[kChooseFBConifgAttCnt + 0] = 1;
        msaaChooseFBConfigAtt[kChooseFBConifgAttCnt + 1] = GLX_SAMPLES_ARB;
        msaaChooseFBConfigAtt[kChooseFBConifgAttCnt + 2] = fRequestedDisplayParams.fMSAASampleCount;
        msaaChooseFBConfigAtt[kChooseFBConifgAttCnt + 3] = None;
        int n;
        fFBConfig = glXChooseFBConfig(fDisplay, DefaultScreen(fDisplay), msaaChooseFBConfigAtt, &n);
        if (n > 0) {
            fVisualInfo = glXGetVisualFromFBConfig(fDisplay, *fFBConfig);
        } else {
            static const GLint kChooseVisualAttCnt = SK_ARRAY_COUNT(chooseVisualAtt);
            GLint msaaChooseVisualAtt[kChooseVisualAttCnt + 4];
            memcpy(msaaChooseVisualAtt, chooseVisualAtt, sizeof(chooseVisualAtt));
            SkASSERT(None == msaaChooseVisualAtt[kChooseVisualAttCnt - 1]);
            msaaChooseFBConfigAtt[kChooseVisualAttCnt - 1] = GLX_SAMPLE_BUFFERS_ARB;
            msaaChooseFBConfigAtt[kChooseVisualAttCnt + 0] = 1;
            msaaChooseFBConfigAtt[kChooseVisualAttCnt + 1] = GLX_SAMPLES_ARB;
            msaaChooseFBConfigAtt[kChooseVisualAttCnt + 2] =
                    fRequestedDisplayParams.fMSAASampleCount;
            msaaChooseFBConfigAtt[kChooseVisualAttCnt + 3] = None;
            fVisualInfo = glXChooseVisual(display, DefaultScreen(display), msaaChooseVisualAtt);
            fFBConfig = nullptr;
        }
    }
    if (nullptr == fVisualInfo) {
        int n;
        fFBConfig = glXChooseFBConfig(fDisplay, DefaultScreen(fDisplay), kChooseFBConfigAtt, &n);
        if (n > 0) {
            fVisualInfo = glXGetVisualFromFBConfig(fDisplay, *fFBConfig);
        } else {
            fVisualInfo = glXChooseVisual(display, DefaultScreen(display), chooseVisualAtt);
            fFBConfig = nullptr;
        }
    }

    if (fVisualInfo) {
        Colormap colorMap = XCreateColormap(display,
                                            RootWindow(display, fVisualInfo->screen),
                                            fVisualInfo->visual,
                                            AllocNone);
        XSetWindowAttributes swa;
        swa.colormap = colorMap;
        swa.event_mask = kEventMask;
        fWindow = XCreateWindow(display,
                                RootWindow(display, fVisualInfo->screen),
                                0, 0, // x, y
                                initialWidth, initialHeight,
                                0, // border width
                                fVisualInfo->depth,
                                InputOutput,
                                fVisualInfo->visual,
                                CWEventMask | CWColormap,
                                &swa);
    } else
#endif // USE(GLX)
    {
        // Create a simple window instead.  We will not be able to show GL
        fWindow = XCreateSimpleWindow(display,
                                      DefaultRootWindow(display),
                                      0, 0,  // x, y
                                      initialWidth, initialHeight,
                                      0,     // border width
                                      0,     // border value
                                      0);    // background value
        XSelectInput(display, fWindow, kEventMask);
    }

    if (!fWindow) {
        return false;
    }

    fMSAASampleCount = fRequestedDisplayParams.fMSAASampleCount;

    // set up to catch window delete message
    fWmDeleteMessage = XInternAtom(display, "WM_DELETE_WINDOW", False);
    XSetWMProtocols(display, fWindow, &fWmDeleteMessage, 1);

    // add to hashtable of windows
    gWindowMap.add(this);

    // init event variables
    fPendingPaint = false;
    fPendingResize = false;

    return true;
}

void WindowX11::closeWindow() {
    if (fDisplay) {
        this->detach();
        if (fGC) {
            XFreeGC(fDisplay, fGC);
            fGC = nullptr;
        }
        gWindowMap.remove(fWindow);
        XDestroyWindow(fDisplay, fWindow);
        fWindow = 0;
#if USE(GLX)
        if (fFBConfig) {
            XFree(fFBConfig);
            fFBConfig = nullptr;
        }
        if (fVisualInfo) {
            XFree(fVisualInfo);
            fVisualInfo = nullptr;
        }
#endif
        fDisplay = nullptr;
    }
}

#if 0
static skui::Key get_key(KeySym keysym) {
    static const struct {
        KeySym      fXK;
        skui::Key fKey;
    } gPair[] = {
        { XK_BackSpace, skui::Key::kBack     },
        { XK_Clear,     skui::Key::kBack     },
        { XK_Return,    skui::Key::kOK       },
        { XK_Up,        skui::Key::kUp       },
        { XK_Down,      skui::Key::kDown     },
        { XK_Left,      skui::Key::kLeft     },
        { XK_Right,     skui::Key::kRight    },
        { XK_Tab,       skui::Key::kTab      },
        { XK_Page_Up,   skui::Key::kPageUp   },
        { XK_Page_Down, skui::Key::kPageDown },
        { XK_Home,      skui::Key::kHome     },
        { XK_End,       skui::Key::kEnd      },
        { XK_Delete,    skui::Key::kDelete   },
        { XK_Escape,    skui::Key::kEscape   },
        { XK_Shift_L,   skui::Key::kShift    },
        { XK_Shift_R,   skui::Key::kShift    },
        { XK_Control_L, skui::Key::kCtrl     },
        { XK_Control_R, skui::Key::kCtrl     },
        { XK_Alt_L,     skui::Key::kOption   },
        { XK_Alt_R,     skui::Key::kOption   },
        { 'A',          skui::Key::kA        },
        { 'C',          skui::Key::kC        },
        { 'V',          skui::Key::kV        },
        { 'X',          skui::Key::kX        },
        { 'Y',          skui::Key::kY        },
        { 'Z',          skui::Key::kZ        },
    };
    for (size_t i = 0; i < SK_ARRAY_COUNT(gPair); i++) {
        if (gPair[i].fXK == keysym) {
            return gPair[i].fKey;
        }
    }
    return skui::Key::kNONE;
}

static skui::ModifierKey get_modifiers(const XEvent& event) {
    static const struct {
        unsigned    fXMask;
        skui::ModifierKey  fSkMask;
    } gModifiers[] = {
        { ShiftMask,   skui::ModifierKey::kShift },
        { ControlMask, skui::ModifierKey::kControl },
        { Mod1Mask,    skui::ModifierKey::kOption },
    };

    skui::ModifierKey modifiers = skui::ModifierKey::kNone;
    for (size_t i = 0; i < SK_ARRAY_COUNT(gModifiers); ++i) {
        if (event.xkey.state & gModifiers[i].fXMask) {
            modifiers |= gModifiers[i].fSkMask;
        }
    }
    return modifiers;
}
#endif

bool WindowX11::handleEvent(const XEvent& event) {
    switch (event.type) {
        case MapNotify:
            if (!fGC) {
                fGC = XCreateGC(fDisplay, fWindow, 0, nullptr);
            }
            break;

        case ClientMessage:
            if ((Atom)event.xclient.data.l[0] == fWmDeleteMessage &&
                gWindowMap.count() == 1) {
                return true;
            }
            break;

        case ButtonPress:
#if 0
         switch (event.xbutton.button) {
                case Button1:
                    this->onMouse(event.xbutton.x, event.xbutton.y,
                                  skui::InputState::kDown, get_modifiers(event));
                    break;
                case Button4:
                    this->onMouseWheel(1.0f, get_modifiers(event));
                    break;
                case Button5:
                    this->onMouseWheel(-1.0f, get_modifiers(event));
                    break;
            }
            break;

        case ButtonRelease:
            if (event.xbutton.button == Button1) {
                this->onMouse(event.xbutton.x, event.xbutton.y,
                              skui::InputState::kUp, get_modifiers(event));
            }
            break;

        case MotionNotify:
            this->onMouse(event.xmotion.x, event.xmotion.y,
                          skui::InputState::kMove, get_modifiers(event));
            break;

        case KeyPress: {
            int shiftLevel = (event.xkey.state & ShiftMask) ? 1 : 0;
            KeySym keysym = XkbKeycodeToKeysym(fDisplay, event.xkey.keycode, 0, shiftLevel);
            skui::Key key = get_key(keysym);
            if (key != skui::Key::kNONE) {
                if (!this->onKey(key, skui::InputState::kDown, get_modifiers(event))) {
                    if (keysym == XK_Escape) {
                        return true;
                    }
                }
            }

            long uni = keysym2ucs(keysym);
            if (uni != -1) {
                (void) this->onChar((SkUnichar) uni, get_modifiers(event));
            }
        } break;

        case KeyRelease: {
            int shiftLevel = (event.xkey.state & ShiftMask) ? 1 : 0;
            KeySym keysym = XkbKeycodeToKeysym(fDisplay, event.xkey.keycode,
                                               0, shiftLevel);
            skui::Key key = get_key(keysym);
            (void) this->onKey(key, skui::InputState::kUp,
                               get_modifiers(event));
        } break;
#endif


        default:
            // these events should be handled in the main event loop
            SkASSERT(event.type != Expose && event.type != ConfigureNotify);
            break;
    }

    return false;
}

void WindowX11::setTitle(const char* title) {
    XTextProperty textproperty;
    XStringListToTextProperty(const_cast<char**>(&title), 1, &textproperty);
    XSetWMName(fDisplay, fWindow, &textproperty);
}

void WindowX11::show() {
    XMapWindow(fDisplay, fWindow);
}

bool WindowX11::attach(BackendType attachType) {
    fBackend = attachType;

    this->initWindow(fPlatformDisplay);

    window_context_factory::UnixWindowInfo winInfo;

    winInfo.fWindow = fWindow;
    winInfo.native.fDisplay = fDisplay;
#if USE(GLX)
    winInfo.native.fFBConfig = fFBConfig;
    winInfo.native.fVisualInfo = fVisualInfo;
#endif

    XWindowAttributes attrs;
    if (XGetWindowAttributes(fDisplay, fWindow, &attrs)) {
        winInfo.fWidth = attrs.width;
        winInfo.fHeight = attrs.height;
    } else {
        winInfo.fWidth = winInfo.fHeight = 0;
    }

    switch (attachType) {
        case kNativeGL_BackendType:
#ifdef SKA_HAS_GPU_SUPPORT
            fWindowContext =
                    window_context_factory::MakeGLForUnix(winInfo, fRequestedDisplayParams);
#else
            SK_APP_LOG_ERROR("Cannot create kNativeGL_BackendType context : GPU SUPPORT IS NOT ENABLED \n");
#endif
            break;
        case kRaster_BackendType:
            fWindowContext =
                    window_context_factory::MakeRasterForUnix(winInfo, fRequestedDisplayParams);
            break;
    }
    this->onBackendCreated();

    return (SkToBool(fWindowContext));
}

void WindowX11::onInval() {
    XEvent event;
    event.type = Expose;
    event.xexpose.send_event = True;
    event.xexpose.display = fDisplay;
    event.xexpose.window = fWindow;
    event.xexpose.x = 0;
    event.xexpose.y = 0;
    event.xexpose.width = this->width();
    event.xexpose.height = this->height();
    event.xexpose.count = 0;

    XSendEvent(fDisplay, fWindow, False, 0, &event);
}

void WindowX11::setRequestedDisplayParams(const DisplayParams& params, bool allowReattach) {
#if defined(SK_VULKAN)
    // Vulkan on unix crashes if we try to reinitialize the vulkan context without remaking the
    // window.
    if (fBackend == kVulkan_BackendType && allowReattach) {
        // Need to change these early, so attach() creates the window context correctly
        fRequestedDisplayParams = params;

        this->detach();
        this->attach(fBackend);
        return;
    }
#endif

    INHERITED::setRequestedDisplayParams(params, allowReattach);
}

}   // namespace sk_app
