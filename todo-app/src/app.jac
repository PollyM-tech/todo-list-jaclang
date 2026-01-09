# ============================================================
# Full Stack Todo App (Jac-Client)
# - Backend: Todo node + walkers (create/read/toggle)
# - Frontend: Auth (login/signup), Router, Dashboard UI
# - SAFE Date handling (no `new Date()`)
# - Responsive sidebar (mobile drawer)
# ============================================================

cl import from react { useState, useEffect }
cl import from "@jac-client/utils" {
    Router,
    Routes,
    Route,
    Link,
    Navigate,
    useNavigate,
    jacSignup,
    jacLogin,
    jacLogout,
    jacIsLoggedIn
}

# -------------------------
# Backend - Todo Node
# -------------------------
node Todo {
    has text: str;
    has done: bool = False;
}

node UserProfile {
    has display_name: str = "Your Account";
    has email: str = "Signed in";
    has avatar_b64: str = "";   # optional (base64 data URL)
}

# -------------------------
# Backend - Walkers
# -------------------------

walker ensure_profile {
    can ensure with `root entry {
        profs = [-->(`?UserProfile)];
        if profs.length == 0 {
            here ++> UserProfile();
        }
        report {"ok": True};
    }
}

walker read_profile {
    can read with `root entry {
        profs = [-->(`?UserProfile)];
        if profs.length == 0 {
            p = here ++> UserProfile();
            report p;
        } else {
            report profs[0];
        }
    }
}

walker update_profile {
    has display_name: str = "";
    has email: str = "";
    has avatar_b64: str = "";

    can update with `root entry {
        profs = [-->(`?UserProfile)];
        p = (here ++> UserProfile()) if profs.length == 0 else profs[0];

        if self.display_name { p.display_name = self.display_name; }
        if self.email { p.email = self.email; }
        if self.avatar_b64 { p.avatar_b64 = self.avatar_b64; }

        report p;
    }
}


walker create_todo {
    has text: str;

    can create with `root entry {
        new_todo = here ++> Todo(text=self.text);
        report new_todo;
    }
}

walker read_todos {
    can read with `root entry {
        visit [-->(`?Todo)];
    }

    can report_todos with Todo entry {
        report here;
    }
}

walker toggle_todo {
    can toggle with Todo entry {
        here.done = not here.done;
        report here;
    }
}

# -------------------------
# Frontend
# -------------------------
cl {
    # ---------- SAFE Date helpers ----------
    def jsNow() -> any {
        # Jac does not allow `new Date()`
        return Reflect.construct(Date, []);
    }

    def greeting() -> str {
    d = jsNow();
    h = d.getHours();
    if h < 12 { return "Good morning"; }
    if h < 18 { return "Good afternoon"; }
    return "Good evening";
}

    def pad2(n: int) -> str {
        s = f"{n}";
        return ("0" + s) if s.length == 1 else s;
    }

    def dayName(d: any) -> str {
        names = ["Sunday","Monday","Tuesday","Wednesday","Thursday","Friday","Saturday"];
        return names[d.getDay()];
    }

    def niceDate() -> any {
        d = jsNow();
        return {
            "day": dayName(d),
            "date": pad2(d.getDate()) + "/" + pad2(d.getMonth()+1) + "/" + f"{d.getFullYear()}"
        };
    }

    def clampText(s: str, n: int) -> str {
        if not s { return ""; }
        return (s.slice(0, n) + "...") if s.length > n else s;
    }

    # ---------- Styles (plain dict only; no functions inside) ----------
    def Styles() -> any {
        return {
            "pageBg": {
                "minHeight":"100vh",
                "background":"linear-gradient(135deg, #f6f7fb 0%, #edf0f7 45%, #eef2f9 100%)",
                "padding":"18px",
                "boxSizing":"border-box",
                "fontFamily":"system-ui, -apple-system, Segoe UI, Roboto, Helvetica, Arial, sans-serif"
            },
            "shell": {
                "maxWidth":"1240px",
                "margin":"0 auto",
                "display":"flex",
                "gap":"16px",
                "alignItems":"stretch"
            },

            "sidebar": {
                "width":"270px",
                "borderRadius":"18px",
                "background":"linear-gradient(180deg, #ff6b6b 0%, #ff6b6b 20%, #ff7a7a 100%)",
                "boxShadow":"0 10px 30px rgba(0,0,0,0.12)",
                "padding":"16px",
                "boxSizing":"border-box",
                "color":"#fff",
                "display":"flex",
                "flexDirection":"column"
            },
            "sbTop": {"display":"flex","alignItems":"center","justifyContent":"space-between","marginBottom":"14px"},
            "sbLogo": {"fontSize":"20px","fontWeight":"900","letterSpacing":"0.2px"},
            "profileCard": {
                "background":"rgba(255,255,255,0.18)",
                "border":"1px solid rgba(255,255,255,0.25)",
                "borderRadius":"16px",
                "padding":"12px",
                "display":"flex",
                "gap":"12px",
                "alignItems":"center",
                "marginBottom":"14px"
            },
            "avatar": {
                "width":"44px",
                "height":"44px",
                "borderRadius":"999px",
                "background":"rgba(255,255,255,0.35)",
                "display":"flex",
                "alignItems":"center",
                "justifyContent":"center",
                "fontWeight":"900"
            },
            "sbName": {"fontWeight":"900","lineHeight":"1.1"},
            "sbEmail": {"fontSize":"12px","opacity":"0.9"},
            "sbSpacer": {"flex":"1"},
            "logoutBtn": {
                "marginTop":"12px",
                "padding":"10px 12px",
                "borderRadius":"12px",
                "background":"rgba(0,0,0,0.20)",
                "border":"1px solid rgba(255,255,255,0.25)",
                "color":"#fff",
                "fontWeight":"900",
                "cursor":"pointer"
            },

            "main": {
                "flex":"1",
                "borderRadius":"18px",
                "background":"rgba(255,255,255,0.55)",
                "border":"1px solid rgba(255,255,255,0.65)",
                "boxShadow":"0 12px 32px rgba(0,0,0,0.10)",
                "backdropFilter":"blur(10px)",
                "padding":"16px",
                "boxSizing":"border-box",
                "minWidth":"0"
            },

            "topbar": {
                "display":"flex",
                "alignItems":"center",
                "justifyContent":"space-between",
                "gap":"12px",
                "marginBottom":"12px"
            },
            "searchWrap": {
                "flex":"1",
                "display":"flex",
                "alignItems":"center",
                "gap":"10px",
                "background":"#fff",
                "border":"1px solid #e5e7eb",
                "borderRadius":"999px",
                "padding":"10px 12px",
                "boxShadow":"0 6px 16px rgba(0,0,0,0.06)",
                "minWidth":"0"
            },
            "searchInput": {
                "border":"none",
                "outline":"none",
                "flex":"1",
                "fontSize":"14px",
                "background":"transparent",
                "minWidth":"0"
            },
            "iconBtn": {
                "width":"38px",
                "height":"38px",
                "borderRadius":"12px",
                "border":"1px solid #e5e7eb",
                "background":"#fff",
                "cursor":"pointer",
                "boxShadow":"0 6px 16px rgba(0,0,0,0.06)",
                "display":"flex",
                "alignItems":"center",
                "justifyContent":"center"
            },
            "dateBox": {
                "textAlign":"right",
                "minWidth":"140px",
                "padding":"6px 10px",
                "borderRadius":"12px",
                "background":"rgba(255,255,255,0.7)",
                "border":"1px solid #e5e7eb"
            },
            "dateDay": {"fontWeight":"900","color":"#111827","fontSize":"13px"},
            "dateVal": {"color":"#3b82f6","fontWeight":"900","fontSize":"12px"},

            "welcomeRow": {
                "display":"flex",
                "alignItems":"center",
                "justifyContent":"space-between",
                "gap":"12px",
                "margin":"4px 0 14px 0"
            },
            "welcomeTitle": {"fontSize":"26px","fontWeight":"900","color":"#111827"},
            "inviteBtn": {
                "padding":"8px 12px",
                "borderRadius":"12px",
                "border":"1px solid #ffd1d1",
                "background":"#fff",
                "cursor":"pointer",
                "fontWeight":"900",
                "color":"#ff6b6b"
            },

            "grid": {
                "display":"grid",
                "gridTemplateColumns":"1.35fr 1fr",
                "gap":"16px",
                "alignItems":"start"
            },
            "card": {
                "background":"rgba(255,255,255,0.82)",
                "border":"1px solid #e5e7eb",
                "borderRadius":"16px",
                "boxShadow":"0 10px 24px rgba(0,0,0,0.06)",
                "padding":"14px",
                "minWidth":"0"
            },
            "cardTitleRow": {
                "display":"flex",
                "alignItems":"center",
                "justifyContent":"space-between",
                "gap":"10px",
                "marginBottom":"10px"
            },
            "cardTitle": {"fontWeight":"900","color":"#111827"},
            "subtle": {"color":"#6b7280","fontSize":"12px","fontWeight":"700"},

            "inputRow": {"display":"flex","gap":"10px","marginBottom":"12px"},
            "textInput": {
                "flex":"1",
                "border":"1px solid #e5e7eb",
                "borderRadius":"12px",
                "padding":"10px 12px",
                "outline":"none",
                "background":"#fff",
                "minWidth":"0"
            },
            "primaryBtn": {
                "padding":"10px 14px",
                "borderRadius":"12px",
                "border":"none",
                "background":"#ff6b6b",
                "color":"#fff",
                "fontWeight":"900",
                "cursor":"pointer",
                "boxShadow":"0 10px 20px rgba(255,107,107,0.28)"
            },

            "filterRow": {"display":"flex","gap":"8px","marginBottom":"6px","flexWrap":"wrap"},

            "taskRow": {
                "display":"flex",
                "gap":"12px",
                "alignItems":"center",
                "padding":"10px",
                "borderRadius":"14px",
                "border":"1px solid #eef2f7",
                "background":"#fff",
                "marginBottom":"10px",
                "minWidth":"0"
            },
            "taskText": {"fontWeight":"900","color":"#111827","fontSize":"13px"},
            "taskMeta": {"color":"#6b7280","fontSize":"12px"},
            "thumb": {
                "width":"52px",
                "height":"40px",
                "borderRadius":"10px",
                "background":"linear-gradient(135deg,#f3f4f6,#e5e7eb)",
                "border":"1px solid #e5e7eb",
                "flex":"0 0 auto"
            },

            "footerStats": {
                "marginTop":"10px",
                "padding":"10px",
                "borderRadius":"14px",
                "background":"#f9fafb",
                "border":"1px solid #eef2f7",
                "display":"flex",
                "justifyContent":"space-between",
                "color":"#6b7280",
                "fontWeight":"900",
                "fontSize":"13px",
                "gap":"10px",
                "flexWrap":"wrap"
            },

            "ringWrap": {"display":"flex","gap":"12px","justifyContent":"space-between","marginTop":"10px"},
            "ringInner": {
                "width":"66px",
                "height":"66px",
                "borderRadius":"999px",
                "background":"#fff",
                "display":"flex",
                "alignItems":"center",
                "justifyContent":"center",
                "flexDirection":"column",
                "border":"1px solid #eef2f7"
            },
            "ringPct": {"fontWeight":"900","color":"#111827","fontSize":"14px"},
            "ringLbl": {"fontSize":"11px","fontWeight":"900","color":"#6b7280"}
        };
    }

    # ---------- Style helpers (functions OUTSIDE Styles dict) ----------
    def navItemStyle(active: bool) -> any {
        return {
            "display":"flex",
            "alignItems":"center",
            "gap":"10px",
            "padding":"10px 12px",
            "borderRadius":"12px",
            "cursor":"pointer",
            "background": ("rgba(255,255,255,0.25)" if active else "transparent"),
            "border": ("1px solid rgba(255,255,255,0.28)" if active else "1px solid transparent"),
            "fontWeight": ("900" if active else "800"),
            "marginBottom":"8px",
            "userSelect":"none"
        };
    }

    def filterBtnStyle(active: bool) -> any {
        return {
            "padding":"7px 10px",
            "borderRadius":"12px",
            "border":"1px solid #e5e7eb",
            "cursor":"pointer",
            "fontWeight":"900",
            "fontSize":"12px",
            "background": ("#111827" if active else "#fff"),
            "color": ("#fff" if active else "#111827")
        };
    }

    def dotStyle(done: bool) -> any {
        return {
            "width":"10px",
            "height":"10px",
            "borderRadius":"999px",
            "background": ("#22c55e" if done else "#3b82f6"),
            "flex":"0 0 auto"
        };
    }

    def pillBtnStyle(kind: str) -> any {
        base = {
            "padding":"6px 10px",
            "borderRadius":"10px",
            "border":"1px solid #e5e7eb",
            "cursor":"pointer",
            "fontWeight":"900",
            "fontSize":"12px",
            "background":"#fff"
        };
        if kind == "danger" {
            base["border"] = "1px solid #fecaca";
            base["color"] = "#ef4444";
        } else {
            base["border"] = "1px solid #dbeafe";
            base["color"] = "#2563eb";
        }
        return base;
    }

    def ringStyle(pct: int, color: str) -> any {
        return {
            "width":"86px",
            "height":"86px",
            "borderRadius":"999px",
            "background": f"conic-gradient({color} {pct}%, #e5e7eb 0)",
            "display":"flex",
            "alignItems":"center",
            "justifyContent":"center"
        };
    }

    # ---------- Sidebar Icons (SVG) ----------
    def SidebarIcon(props: any) -> any {
        kind = props["kind"];
        # Use white strokes like the screenshot
        base = {"width":"18","height":"18","viewBox":"0 0 24 24","fill":"none","stroke":"currentColor","strokeWidth":"2","strokeLinecap":"round","strokeLinejoin":"round"};
        wrapStyle = {"color":"#ffffff","display":"flex","alignItems":"center","justifyContent":"center"};

        if kind == "dashboard" {
            return <span style={wrapStyle}>
                <svg {...base}>
                    <path d="M3 13h8V3H3v10z" />
                    <path d="M13 21h8V11h-8v10z" />
                    <path d="M13 3h8v6h-8V3z" />
                    <path d="M3 17h8v4H3v-4z" />
                </svg>
            </span>;
        } elif kind == "vital" {
            return <span style={wrapStyle}>
                <svg {...base}>
                    <path d="M3 12h4l2-6 4 12 2-6h4" />
                    <path d="M21 12h0" />
                </svg>
            </span>;
        } elif kind == "task" {
            return <span style={wrapStyle}>
                <svg {...base}>
                    <path d="M9 11l3 3L22 4" />
                    <path d="M21 12v7a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h11" />
                </svg>
            </span>;
        } elif kind == "categories" {
            return <span style={wrapStyle}>
                <svg {...base}>
                    <path d="M4 4h7v7H4V4z" />
                    <path d="M13 4h7v7h-7V4z" />
                    <path d="M4 13h7v7H4v-7z" />
                    <path d="M13 13h7v7h-7v-7z" />
                </svg>
            </span>;
        } elif kind == "settings" {
            return <span style={wrapStyle}>
                <svg {...base}>
                    <path d="M12 15.5a3.5 3.5 0 1 0 0-7 3.5 3.5 0 0 0 0 7z" />
                    <path d="M19.4 15a1.8 1.8 0 0 0 .4 2l.1.1a2 2 0 0 1-1.4 3.4h-.2a1.9 1.9 0 0 0-1.8 1.3l-.1.2a2 2 0 0 1-3.7 0l-.1-.2a1.9 1.9 0 0 0-1.8-1.3H9.5a2 2 0 0 1-1.4-3.4l.1-.1a1.8 1.8 0 0 0 .4-2 1.8 1.8 0 0 0-1.6-1H7a2 2 0 0 1 0-4h.1a1.8 1.8 0 0 0 1.6-1 1.8 1.8 0 0 0-.4-2l-.1-.1A2 2 0 0 1 9.5 3h.2a1.9 1.9 0 0 0 1.8-1.3l.1-.2a2 2 0 0 1 3.7 0l.1.2A1.9 1.9 0 0 0 17.2 3h.2a2 2 0 0 1 1.4 3.4l-.1.1a1.8 1.8 0 0 0-.4 2 1.8 1.8 0 0 0 1.6 1H20a2 2 0 0 1 0 4h-.1a1.8 1.8 0 0 0-1.6 1z" />
                </svg>
            </span>;
        } elif kind == "help" {
            return <span style={wrapStyle}>
                <svg {...base}>
                    <path d="M9.1 9a3 3 0 1 1 5.8 1c0 2-3 2-3 4" />
                    <path d="M12 17h.01" />
                    <path d="M21 12a9 9 0 1 1-18 0 9 9 0 0 1 18 0z" />
                </svg>
            </span>;
        }

        return <span style={wrapStyle}>•</span>;
    }
    # ---------- Header / Navigation ----------
    def Navigation() -> any {
        isLoggedIn = jacIsLoggedIn();
        navigate = useNavigate();

        # Show header always; show auth links only when NOT logged in
        return <div style={{
            "position":"sticky",
            "top":"0",
            "zIndex":"20",
            "padding":"12px 20px",
            "background":"rgba(246,247,251,0.85)",
            "backdropFilter":"blur(10px)",
            "borderBottom":"1px solid rgba(229,231,235,0.9)",
            "display":"flex",
            "justifyContent":"space-between",
            "alignItems":"center"
        }}>
            <div style={{"fontWeight":"900", "color":"#111827"}}>
                Todo App
            </div>

            {(
                <div style={{"display":"flex","gap":"12px"}}>
                    <Link
                        to="/login"
                        style={{
                            "color":"#111827",
                            "fontWeight":"800",
                            "textDecoration":"none"
                        }}
                    >
                        Login
                    </Link>
                    <Link
                        to="/signup"
                        style={{
                            "color":"#111827",
                            "fontWeight":"800",
                            "textDecoration":"none"
                        }}
                    >
                        Sign Up
                    </Link>
                </div>
            ) if not isLoggedIn else None}
        </div>;
    }

    # ---------- Login ----------
    def LoginPage() -> any {
        [username, setUsername] = useState("");
        [password, setPassword] = useState("");
        [error, setError] = useState("");
        navigate = useNavigate();

        async def handleLogin(e: any) -> None {
            e.preventDefault();
            setError("");
            if not username or not password {
                setError("Please fill in all fields");
                return;
            }
            success = await jacLogin(username, password);
            if success { navigate("/todos"); }
            else { setError("Invalid credentials"); }
        }

        return <div style={{
            "minHeight":"100vh",
            "display":"flex",
            "alignItems":"center",
            "justifyContent":"center",
            "background":"linear-gradient(135deg, #f6f7fb, #eef2f9)"
        }}>
            <div style={{
                "background":"rgba(255,255,255,0.9)",
                "border":"1px solid #e5e7eb",
                "padding":"30px",
                "borderRadius":"16px",
                "width":"320px",
                "boxShadow":"0 12px 30px rgba(0,0,0,0.10)"
            }}>
                <h2 style={{"margin":"0 0 16px 0", "color":"#111827"}}>Login</h2>

                {(
                    <div style={{"color":"#dc2626","fontWeight":"800","fontSize":"13px","marginBottom":"10px"}}>
                        {error}
                    </div>
                ) if error else None}

                <form onSubmit={handleLogin}>
                    <input
                        type="text"
                        value={username}
                        onChange={lambda e: any -> None { setUsername(e.target.value); }}
                        placeholder="Username"
                        style={{
                            "width":"100%",
                            "padding":"10px 12px",
                            "marginBottom":"10px",
                            "border":"1px solid #e5e7eb",
                            "borderRadius":"12px",
                            "boxSizing":"border-box",
                            "outline":"none"
                        }}
                    />
                    <input
                        type="password"
                        value={password}
                        onChange={lambda e: any -> None { setPassword(e.target.value); }}
                        placeholder="Password"
                        style={{
                            "width":"100%",
                            "padding":"10px 12px",
                            "marginBottom":"12px",
                            "border":"1px solid #e5e7eb",
                            "borderRadius":"12px",
                            "boxSizing":"border-box",
                            "outline":"none"
                        }}
                    />
                    <button type="submit" style={{
                        "width":"100%",
                        "padding":"10px",
                        "background":"#ff6b6b",
                        "color":"#fff",
                        "border":"none",
                        "borderRadius":"12px",
                        "cursor":"pointer",
                        "fontWeight":"900",
                        "boxShadow":"0 10px 20px rgba(255,107,107,0.28)"
                    }}>
                        Login
                    </button>
                </form>

                <p style={{"textAlign":"center","marginTop":"12px","fontSize":"14px"}}>
                    Need an account? <Link to="/signup">Sign up</Link>
                </p>
            </div>
        </div>;
    }

       # ---------- Signup ----------
    def SignupPage() -> any {
        [username, setUsername] = useState("");
        [password, setPassword] = useState("");
        [error, setError] = useState("");
        [fullName, setFullName] = useState("");
        navigate = useNavigate();

        async def handleSignup(e: any) -> None {
            e.preventDefault();
            setError("");

            if not username or not password {
                setError("Please fill in all fields");
                return;
            }

            result = await jacSignup(username, password);

            if result["success"] {
                pretty = (fullName.trim() if fullName and fullName.trim() else username);

                # make sure profile exists, then update it
                await root spawn ensure_profile();
                await root spawn update_profile(display_name=pretty, email=username);

                navigate("/todos");
            } else {
                setError(result["error"] if result["error"] else "Signup failed");
            }
        }

        return <div style={{
            "minHeight":"100vh",
            "display":"flex",
            "alignItems":"center",
            "justifyContent":"center",
            "background":"linear-gradient(135deg, #f6f7fb, #eef2f9)"
        }}>
            <div style={{
                "background":"rgba(255,255,255,0.9)",
                "border":"1px solid #e5e7eb",
                "padding":"30px",
                "borderRadius":"16px",
                "width":"320px",
                "boxShadow":"0 12px 30px rgba(0,0,0,0.10)"
            }}>
                <h2 style={{"margin":"0 0 16px 0", "color":"#111827"}}>Sign Up</h2>

                {(
                    <div style={{"color":"#dc2626","fontWeight":"800","fontSize":"13px","marginBottom":"10px"}}>
                        {error}
                    </div>
                ) if error else None}

                <form onSubmit={handleSignup}>
                    <input
                        type="text"
                        value={fullName}
                        onChange={lambda e: any -> None { setFullName(e.target.value); }}
                        placeholder="Full name"
                        style={{
                            "width":"100%",
                            "padding":"10px 12px",
                            "marginBottom":"10px",
                            "border":"1px solid #e5e7eb",
                            "borderRadius":"12px",
                            "boxSizing":"border-box",
                            "outline":"none"
                        }}
                    />

                    <input
                        type="text"
                        value={username}
                        onChange={lambda e: any -> None { setUsername(e.target.value); }}
                        placeholder="Username or email"
                        style={{
                            "width":"100%",
                            "padding":"10px 12px",
                            "marginBottom":"10px",
                            "border":"1px solid #e5e7eb",
                            "borderRadius":"12px",
                            "boxSizing":"border-box",
                            "outline":"none"
                        }}
                    />

                    <input
                        type="password"
                        value={password}
                        onChange={lambda e: any -> None { setPassword(e.target.value); }}
                        placeholder="Password"
                        style={{
                            "width":"100%",
                            "padding":"10px 12px",
                            "marginBottom":"12px",
                            "border":"1px solid #e5e7eb",
                            "borderRadius":"12px",
                            "boxSizing":"border-box",
                            "outline":"none"
                        }}
                    />

                    <button type="submit" style={{
                        "width":"100%",
                        "padding":"10px",
                        "background":"#111827",
                        "color":"#fff",
                        "border":"none",
                        "borderRadius":"12px",
                        "cursor":"pointer",
                        "fontWeight":"900",
                        "boxShadow":"0 10px 18px rgba(17,24,39,0.20)"
                    }}>
                        Create account
                    </button>
                </form>

                <p style={{"textAlign":"center","marginTop":"12px","fontSize":"14px"}}>
                    Have an account? <Link to="/login">Login</Link>
                </p>
            </div>
        </div>;
    }


    # ---------- Placeholder content for other sidebar tabs ----------
    def PlaceholderTab(props: any) -> any {
        styles = Styles();
        title = props["title"];
        desc = props["desc"];

        return <div style={styles.card}>
            <div style={styles.cardTitleRow}>
                <div style={styles.cardTitle}>{title}</div>
            </div>
            <div style={{"color":"#6b7280","fontWeight":"700","lineHeight":"1.5"}}>
                {desc}
            </div>
        </div>;
    }

    # ---------- Dashboard main content (Todo UI) ----------
    def DashboardContent(props: any) -> any {
        styles = Styles();
        state = props["state"];

        todos = state["todos"];
        setTodos = state["setTodos"];
        input = state["input"];
        setInput = state["setInput"];
        filter = state["filter"];
        setFilter = state["setFilter"];
        search = state["search"];
        setSearch = state["setSearch"];

        def getFilteredTodos() -> any {
            items = todos;

            if search and search.trim() {
                q = search.trim().toLowerCase();
                items = items.filter(lambda t: any -> bool { return t.text.toLowerCase().includes(q); });
            }

            if filter == "active" {
                return items.filter(lambda t: any -> bool { return not t.done; });
            } elif filter == "completed" {
                return items.filter(lambda t: any -> bool { return t.done; });
            }
            return items;
        }

        filtered = getFilteredTodos();
        activeCount = todos.filter(lambda t: any -> bool { return not t.done; }).length;
        total = todos.length;
        completed = total - activeCount;

        pctCompleted = (Math.round((completed / total) * 100) if total > 0 else 0);
        pctInProgress = (Math.round((activeCount / total) * 100) if total > 0 else 0);
        pctNotStarted = 0;

        today = niceDate();

        async def addTodo() -> None {
            if not input or not input.trim() { return; }
            result = await root spawn create_todo(text=input.trim());
            if result.reports and result.reports.length > 0 {
                setTodos([result.reports[0][0]].concat(todos));
            }
            setInput("");
        }

        async def toggleTodo(id: any) -> None {
            await id spawn toggle_todo();
            setTodos(
                todos.map(lambda t: any -> any {
                    if t._jac_id == id {
                        return {"_jac_id": t._jac_id, "text": t.text, "done": not t.done};
                    }
                    return t;
                })
            );
        }

        async def deleteTodo(id: any) -> None {
            setTodos(todos.filter(lambda t: any -> bool { return t._jac_id != id; }));
        }

        return <div style={styles.grid}>
            <div style={styles.card}>
                <div style={styles.cardTitleRow}>
                    <div>
                        <div style={styles.cardTitle}>To-Do</div>
                        <div style={styles.subtle}>{today.day} • {today.date}</div>
                    </div>
                </div>

                <div style={styles.inputRow}>
                    <input
                        value={input}
                        onChange={lambda e: any -> None { setInput(e.target.value); }}
                        onKeyPress={lambda e: any -> None { if e.key == "Enter" { addTodo(); } }}
                        placeholder="Create a new task..."
                        style={styles.textInput}
                    />
                    <button style={styles.primaryBtn} onClick={addTodo}>Add</button>
                </div>

                <div style={styles.filterRow}>
                    <button style={filterBtnStyle(filter=="all")} onClick={lambda -> None { setFilter("all"); }}>All</button>
                    <button style={filterBtnStyle(filter=="active")} onClick={lambda -> None { setFilter("active"); }}>Active</button>
                    <button style={filterBtnStyle(filter=="completed")} onClick={lambda -> None { setFilter("completed"); }}>Completed</button>
                </div>

                <div style={{"marginTop":"10px"}}>
                    {(
                        <div style={{
                            "padding":"16px",
                            "textAlign":"center",
                            "color":"#6b7280",
                            "border":"1px dashed #e5e7eb",
                            "borderRadius":"14px",
                            "background":"rgba(255,255,255,0.6)"
                        }}>
                            No tasks found. Add one above!
                        </div>
                    ) if filtered.length == 0 else (
                        filtered.map(lambda t: any -> any {
                            return <div key={t._jac_id} style={styles.taskRow}>
                                <div style={dotStyle(t.done)}></div>

                                <div style={{"flex":"1","minWidth":"0"}}>
                                    <div style={styles.taskText}>{clampText(t.text, 64)}</div>
                                    <div style={styles.taskMeta}>
                                        Status: {("Completed" if t.done else "In Progress")}
                                    </div>
                                </div>

                                <div style={styles.thumb}></div>

                                <div style={{"display":"flex","gap":"8px","alignItems":"center","flexWrap":"wrap"}}>
                                    <button style={pillBtnStyle("primary")} onClick={lambda -> None { toggleTodo(t._jac_id); }}>
                                        {("Undo" if t.done else "Done")}
                                    </button>
                                    <button style={pillBtnStyle("danger")} onClick={lambda -> None { deleteTodo(t._jac_id); }}>
                                        Delete
                                    </button>
                                </div>
                            </div>;
                        })
                    )}
                </div>

                <div style={styles.footerStats}>
                    <span>{activeCount} active</span>
                    <span>{completed} completed</span>
                    <span>{total} total</span>
                </div>
            </div>

            <div style={{"display":"flex","flexDirection":"column","gap":"16px","minWidth":"0"}}>
                <div style={styles.card}>
                    <div style={styles.cardTitleRow}>
                        <div style={styles.cardTitle}>Task Status</div>
                    </div>

                    <div style={styles.ringWrap}>
                        <div style={{"textAlign":"center","flex":"1"}}>
                            <div style={ringStyle(pctCompleted, "#22c55e")}>
                                <div style={styles.ringInner}>
                                    <div style={styles.ringPct}>{pctCompleted}%</div>
                                    <div style={styles.ringLbl}>Completed</div>
                                </div>
                            </div>
                        </div>

                        <div style={{"textAlign":"center","flex":"1"}}>
                            <div style={ringStyle(pctInProgress, "#3b82f6")}>
                                <div style={styles.ringInner}>
                                    <div style={styles.ringPct}>{pctInProgress}%</div>
                                    <div style={styles.ringLbl}>In Progress</div>
                                </div>
                            </div>
                        </div>

                        <div style={{"textAlign":"center","flex":"1"}}>
                            <div style={ringStyle(pctNotStarted, "#ef4444")}>
                                <div style={styles.ringInner}>
                                    <div style={styles.ringPct}>{pctNotStarted}%</div>
                                    <div style={styles.ringLbl}>Not Started</div>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>

                <div style={styles.card}>
                    <div style={styles.cardTitleRow}>
                        <div style={styles.cardTitle}>Completed Task</div>
                    </div>

                    {(
                        <div style={{
                            "padding":"14px",
                            "border":"1px dashed #e5e7eb",
                            "borderRadius":"14px",
                            "color":"#6b7280",
                            "textAlign":"center"
                        }}>
                            No completed tasks yet.
                        </div>
                    ) if completed == 0 else (
                        todos.filter(lambda t: any -> bool { return t.done; })
                            .slice(0, 4)
                            .map(lambda t: any -> any {
                                return <div key={t._jac_id} style={styles.taskRow}>
                                    <div style={dotStyle(true)}></div>
                                    <div style={{"flex":"1","minWidth":"0"}}>
                                        <div style={styles.taskText}>{clampText(t.text, 54)}</div>
                                        <div style={styles.taskMeta}>Status: Completed</div>
                                    </div>
                                    <div style={styles.thumb}></div>
                                    <button style={pillBtnStyle("primary")} onClick={lambda -> None { toggleTodo(t._jac_id); }}>
                                        Undo
                                    </button>
                                </div>;
                            })
                    )}
                </div>
            </div>
        </div>;
    }

    # ---------- Todos Page (Protected + Dashboard Shell) ----------
    def TodosPage() -> any {
        if not jacIsLoggedIn() { return <Navigate to="/login" />; }

        styles = Styles();
        navigate = useNavigate();

        [profile, setProfile] = useState(None);
        [activeTab, setActiveTab] = useState("dashboard");
        [sidebarOpen, setSidebarOpen] = useState(false);
        [isMobile, setIsMobile] = useState(false);

        [todos, setTodos] = useState([]);
        [input, setInput] = useState("");
        [filter, setFilter] = useState("all");
        [search, setSearch] = useState("");
        [loading, setLoading] = useState(true);

        useEffect(lambda -> None {
            def update() -> None {
                w = window.innerWidth;
                setIsMobile(w < 900);
                if w >= 900 { setSidebarOpen(false); }
            }
            update();
            window.addEventListener("resize", update);
            return lambda -> None { window.removeEventListener("resize", update); };
        }, []);

        useEffect(lambda -> None {
            async def loadProfile() -> None {
                await root spawn ensure_profile();
                r = await root spawn read_profile();
                if r.reports and r.reports.length > 0 {
                    setProfile(r.reports[0][0]);
                }
            }
            loadProfile();
        }, []);


        useEffect(lambda -> None {
            async def loadTodos() -> None {
                result = await root spawn read_todos();
                setTodos(result.reports if result.reports else []);
                setLoading(false);
            }
            loadTodos();
        }, []);

        def doLogout(e: any) -> None {
            e.preventDefault();
            jacLogout();
            navigate("/login");
        }

        today = niceDate();
        name = (profile.display_name if profile else "Your Account");
        welcomeText = greeting() + ", " + name;


        # Sidebar as inline component
        def Sidebar() -> any {
            sbName = (profile.display_name if profile else "Your Account");
            sbEmail = (profile.email if profile else "Signed in");
            avatarB64 = (profile.avatar_b64 if profile else "");
            initial = (sbName.slice(0,1).toUpperCase() if sbName else "U");
            return <div style={styles.sidebar}>
                <div style={styles.sbTop}>
                    <div style={styles.sbLogo}>Task Manager</div>
                    {(
                        <button
                            style={{
                                "border":"1px solid rgba(255,255,255,0.35)",
                                "background":"rgba(0,0,0,0.18)",
                                "color":"#fff",
                                "borderRadius":"12px",
                                "padding":"6px 10px",
                                "cursor":"pointer",
                                "fontWeight":"900"
                            }}
                            onClick={lambda -> None { setSidebarOpen(false); }}
                        >
                            ✕
                        </button>
                    ) if isMobile else None}
                </div>

                <div style={styles.profileCard}>
                {(
                    <img
                    src={avatarB64}
                    style={{
                        "width":"46px",
                        "height":"46px",
                        "borderRadius":"999px",
                        "objectFit":"cover",
                        "border":"2px solid rgba(255,255,255,0.35)"
                        }}
                        />
                        ) if avatarB64 else (
                            <div style={styles.avatar}>{initial}</div>
                            )}
                            <div>
                            <div style={styles.sbName}>{sbName}</div>
                            <div style={styles.sbEmail}>{sbEmail}</div>
                            </div>
                            </div>


                <div style={navItemStyle(activeTab == "dashboard")}
                    onClick={lambda -> None { setActiveTab("dashboard"); setSidebarOpen(false); }}>
                    <SidebarIcon kind="dashboard" />
                    <span>Dashboard</span>
                </div>

                <div style={navItemStyle(activeTab == "vital")}
                    onClick={lambda -> None { setActiveTab("vital"); setSidebarOpen(false); }}>
                    <SidebarIcon kind="vital" />
                    <span>Vital Task</span>
                </div>

                <div style={navItemStyle(activeTab == "my")}
                    onClick={lambda -> None { setActiveTab("my"); setSidebarOpen(false); }}>
                    <SidebarIcon kind="task" />
                    <span>My Task</span>
                </div>

                <div style={navItemStyle(activeTab == "categories")}
                    onClick={lambda -> None { setActiveTab("categories"); setSidebarOpen(false); }}>
                    <SidebarIcon kind="categories" />
                    <span>Task Categories</span>
                </div>

                <div style={navItemStyle(activeTab == "settings")}
                    onClick={lambda -> None { setActiveTab("settings"); setSidebarOpen(false); }}>
                    <SidebarIcon kind="settings" />
                    <span>Settings</span>
                </div>

                <div style={navItemStyle(activeTab == "help")}
                    onClick={lambda -> None { setActiveTab("help"); setSidebarOpen(false); }}>
                    <SidebarIcon kind="help" />
                    <span>Help</span>
                </div>

                <div style={styles.sbSpacer}></div>

                <button style={styles.logoutBtn} onClick={doLogout}>⎋ Logout</button>
            </div>;
        }

                # ---------- (5F) Settings Tab: Upload avatar ----------
        def SettingsTab() -> any {
            sbName = (profile.display_name if profile else "Your Account");
            return <div style={styles.card}>
                <div style={styles.cardTitleRow}>
                    <div style={styles.cardTitle}>Settings</div>
                </div>

                <div style={{"color":"#6b7280","fontWeight":"800","marginBottom":"10px"}}>
                    Update your profile picture (it will show in the sidebar).
                </div>

                <div style={{
                    "display":"flex",
                    "gap":"12px",
                    "alignItems":"center",
                    "flexWrap":"wrap"
                }}>
                    <input
                        type="file"
                        accept="image/*"
                        onChange={lambda e: any -> None {
                            file = e.target.files[0];
                            if not file { return; }
                            reader = Reflect.construct(FileReader, []);
                            async def handleLoad(_: any) -> None {
                                dataUrl = reader.result;
                                r = await root spawn update_profile(
                                    display_name=sbName,
                                    avatar_b64=dataUrl
                                );
                                if r.reports and r.reports.length > 0 {
                                    setProfile(r.reports[0][0]);
                                }
                            }

                            # onload must be a normal function; it can call the async function
                            reader.onload = lambda ev: any -> None { handleLoad(ev); };

                            reader.readAsDataURL(file);
                            # dataUrl = reader.result;
                            # if not dataUrl { return; }
                        }}

                        style={{
                            "padding":"10px",
                            "border":"1px solid #e5e7eb",
                            "borderRadius":"12px",
                            "background":"#fff",
                            "cursor":"pointer"
                        }}
                    />

                    <div style={{
                        "fontSize":"12px",
                        "fontWeight":"800",
                        "color":"#6b7280"
                    }}>
                        Tip: choose a square photo for best results.
                    </div>
                </div>
            </div>;
        }

        if loading {
            return <div style={{
                "minHeight":"100vh",
                "display":"flex",
                "alignItems":"center",
                "justifyContent":"center",
                "background":"linear-gradient(135deg, #f6f7fb, #eef2f9)",
                "fontFamily":"system-ui, -apple-system, Segoe UI, Roboto, Helvetica, Arial, sans-serif"
            }}>
                <h2 style={{"color":"#111827"}}>Loading dashboard...</h2>
            </div>;
        }

        # Main content changes by tab
        content = None;
        if activeTab == "dashboard" {
            content = <DashboardContent state={{
                "todos": todos,
                "setTodos": setTodos,
                "input": input,
                "setInput": setInput,
                "filter": filter,
                "setFilter": setFilter,
                "search": search,
                "setSearch": setSearch
            }} />;
        } elif activeTab == "vital" {
            content = <PlaceholderTab title="Vital Task" desc="You can build a priority view here: show only active tasks, add priority flags, deadlines, or reminders." />;
        } elif activeTab == "my" {
            content = <PlaceholderTab title="My Task" desc="This can become your personal task list view. Later we can add tags, due dates, and sorting." />;
        } elif activeTab == "categories" {
            content = <PlaceholderTab title="Task Categories" desc="Add categories/tags and filter tasks by category. We can extend the Todo node with category fields." />;
        } elif activeTab == "settings" {
            content = <SettingsTab />;
        } else {
            content = <PlaceholderTab title="Help" desc="Add FAQs, keyboard shortcuts, or a simple guide to using your dashboard." />;
        }

        return <div style={styles.pageBg}>
            <div style={styles.shell}>

                {(
                    <div style={{
                        "position":"fixed",
                        "inset":"0",
                        "background":"rgba(0,0,0,0.35)",
                        "zIndex":"50",
                        "display":"flex"
                    }}>
                        <div style={{"width":"82%", "maxWidth":"320px"}}>
                            <Sidebar />
                        </div>
                        <div style={{"flex":"1"}} onClick={lambda -> None { setSidebarOpen(false); }}></div>
                    </div>
                ) if (isMobile and sidebarOpen) else None}

                {(Sidebar()) if not isMobile else None}

                <div style={styles.main}>
                    <div style={styles.topbar}>
                        {(
                            <button
                                style={{
                                    "width":"42px",
                                    "height":"42px",
                                    "borderRadius":"12px",
                                    "border":"1px solid #e5e7eb",
                                    "background":"#fff",
                                    "cursor":"pointer",
                                    "boxShadow":"0 6px 16px rgba(0,0,0,0.06)",
                                    "display":"flex",
                                    "alignItems":"center",
                                    "justifyContent":"center",
                                    "fontWeight":"900"
                                }}
                                onClick={lambda -> None { setSidebarOpen(true); }}
                            >
                                ☰
                            </button>
                        ) if isMobile else None}

                        <div style={styles.searchWrap}>
                            <input
                                value={search}
                                onChange={lambda e: any -> None { setSearch(e.target.value); }}
                                placeholder="Search your task here..."
                                style={styles.searchInput}
                            />
                            <button style={{
                                "border":"none",
                                "background":"#ff6b6b",
                                "color":"#fff",
                                "fontWeight":"900",
                                "borderRadius":"12px",
                                "padding":"8px 12px",
                                "cursor":"pointer"
                            }}>
                                🔍
                            </button>
                        </div>

                        <button style={styles.iconBtn}>🔔</button>
                        <button style={styles.iconBtn}>📅</button>

                        <div style={styles.dateBox}>
                            <div style={styles.dateDay}>{today.day}</div>
                            <div style={styles.dateVal}>{today.date}</div>
                        </div>
                    </div>

                    <div style={styles.welcomeRow}>
                        <div style={styles.welcomeTitle}>{welcomeText} 👋</div>
                        <button style={styles.inviteBtn}>＋ Invite</button>
                    </div>

                    {content}
                </div>
            </div>
        </div>;
    }

        # ---------- Landing / Root ----------
    def HomePage() -> any {
        # Route "/" inside the SPA:
        # If logged in => go to todos, else => login
        if jacIsLoggedIn() {
            return <Navigate to="/todos" replace={true} />;
        }
        return <Navigate to="/login" replace={true} />;
    }

    # ---------- App ----------
    def:pub app() -> any {
        # If user opens /page/app (no hash route yet),
        # force the correct hash so Router loads the right page.
        # This runs BEFORE Router renders.
        if (not window.location.hash) or (window.location.hash == "#") {
            if jacIsLoggedIn() {
                window.location.hash = "#/todos";
            } else {
                window.location.hash = "#/login";
            }
        }

        return <Router>
            <div>
                <Navigation />
                <Routes>
                    <Route path="/" element={<HomePage />} />
                    <Route path="/login" element={<LoginPage />} />
                    <Route path="/signup" element={<SignupPage />} />
                    <Route path="/todos" element={<TodosPage />} />

                    # Catch-all: anything else goes through HomePage redirect logic
                    <Route path="*" element={<HomePage />} />
                </Routes>
            </div>
        </Router>;
    }

}
