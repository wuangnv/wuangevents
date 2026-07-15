const manifest = await fetch("manifest.json").then(response => response.json());
const query = new URLSearchParams(location.search);
const selectedScreen = query.get("screen");
const renderMode = query.get("mode") === "render" || Boolean(selectedScreen);
const previewCanvas = { width: 1366, height: 800 };

const roles = {
  GUEST: "Khách",
  CUSTOMER: "Khách hàng",
  ORGANIZER: "Ban tổ chức",
  STAFF: "Nhân viên soát vé",
  ADMIN: "Quản trị viên"
};

const boards = {
  M0: "Nền tảng giao diện",
  M1: "Khám phá và tài khoản",
  M2: "Đặt vé và thanh toán",
  M3: "Thiết lập sự kiện",
  M4: "Vận hành sự kiện",
  M5: "Nhân viên soát vé",
  M6: "Quản trị hệ thống"
};

const events = [
  ["Ben Thanh Concert 2026", "Nhà hát Thành phố", "20:00 · 18/08/2026", "Từ 450.000đ", ""],
  ["Vietnam Game Connect", "SECC, Quận 7", "08:30 · 24/08/2026", "Từ 150.000đ", "blue"],
  ["Saigon Midnight Run", "Phố đi bộ Nguyễn Huệ", "23:00 · 30/08/2026", "Từ 299.000đ", "orange"],
  ["Green Living Fair", "Thiso Mall Sala", "09:00 · 05/09/2026", "Miễn phí", "green"],
  ["VCT Pacific Finals", "Nhà thi đấu Phú Thọ", "16:00 · 12/09/2026", "Từ 350.000đ", "blue"],
  ["Saigon Vintage Market", "The Factory", "10:00 · 20/09/2026", "Từ 80.000đ", "orange"]
];

const orderRows = [
  ["WE260812-0482", "Ben Thanh Concert", "2 vé", "900.000đ", "Đã thanh toán", "success"],
  ["WE260805-0311", "Vietnam Game Connect", "1 vé", "150.000đ", "Chờ thanh toán", "warning"],
  ["WE260720-0207", "Saigon Midnight Run", "3 vé", "897.000đ", "Đã thanh toán", "success"],
  ["WE260611-0184", "Indie Film Weekend", "2 vé", "360.000đ", "Đã hủy", "danger"]
];

const eventRows = [
  ["Ben Thanh Concert 2026", "Âm nhạc", "18/08/2026", "Đang bán vé", "success", "1.842 vé"],
  ["Vietnam Game Connect", "Hội thảo", "24/08/2026", "Chờ duyệt", "warning", "—"],
  ["Saigon Midnight Run", "Thể thao", "30/08/2026", "Bản nháp", "muted", "—"],
  ["Green Living Fair", "Triển lãm", "05/09/2026", "Đang bán vé", "success", "628 vé"],
  ["Indie Film Weekend", "Nghệ thuật", "14/09/2026", "Từ chối", "danger", "—"]
];

const userRows = [
  ["Nguyễn Minh Anh", "minhanh@gmail.com", "Khách hàng", "Hoạt động", "success"],
  ["Trần Quốc Huy", "huy.events@gmail.com", "Ban tổ chức", "Hoạt động", "success"],
  ["Lê Hoàng Phúc", "phuc.staff@gmail.com", "Nhân viên soát vé", "Hoạt động", "success"],
  ["Phạm Thanh Hà", "ha.organizer@gmail.com", "Ban tổ chức", "Đang khóa", "danger"],
  ["Admin WuangEvents", "admin@wuangevents.com", "Quản trị viên", "Hoạt động", "success"]
];

const badge = (text, style = "muted") => `<span class="badge ${style}">${text}</span>`;
const button = (text, style = "secondary", small = false) => `<button class="btn btn-${style}${small ? " btn-sm" : ""}" type="button">${text}</button>`;
const field = (placeholder, type = "input") => type === "select"
  ? `<select class="field"><option>${placeholder}</option><option>Tất cả</option></select>`
  : `<input class="field search" placeholder="${placeholder}">`;

function eventCards(limit = 6) {
  return `<div class="event-grid">${events.slice(0, limit).map(([name, place, time, price, color]) => `
    <article class="event-card">
      <div class="event-cover ${color}">${badge("Đang mở bán", "success")}<div class="event-date">${time}</div></div>
      <div class="event-body"><h3>${name}</h3><div class="event-meta"><span>⌖ ${place}</span><span>◷ ${time}</span></div><div class="event-price">${price}</div></div>
    </article>`).join("")}</div>`;
}

function table(headers, rows, widths = [], footer = "") {
  const cols = widths.length ? `<colgroup>${widths.map(width => `<col style="width:${width}">`).join("")}</colgroup>` : "";
  return `<div class="table-wrap"><table class="data-table">${cols}<thead><tr>${headers.map(header => `<th>${header}</th>`).join("")}</tr></thead><tbody>
    ${rows.map(row => `<tr>${row.map(cell => `<td>${cell}</td>`).join("")}</tr>`).join("")}
  </tbody></table>${footer ? `<div class="table-footer"><span>${footer}</span><div class="pager"><span>‹</span><span class="active">1</span><span>2</span><span>3</span><span>›</span></div></div>` : ""}</div>`;
}

function kpis(items) {
  return `<div class="grid grid-${items.length}">${items.map(([label, value, note, icon]) => `<div class="card kpi"><span class="kpi-icon">${icon}</span><div class="kpi-label">${label}</div><div class="kpi-value">${value}</div><div class="kpi-note">${note}</div></div>`).join("")}</div>`;
}

function bars(values = [62, 74, 48, 88, 65, 92, 72, 55, 84, 68, 95, 78]) {
  return `<div class="chart">${values.map((value, index) => `<div class="bar-group"><i class="bar" style="height:${value}%"></i><i class="bar alt" style="height:${Math.max(18, value - 23)}%"></i></div>`).join("")}</div>`;
}

function publicNav() {
  return `<nav class="public-nav"><div class="brand"><span class="brand-mark">ϟ</span><span>Wuang<em>Events</em></span></div><div class="nav-search">⌕ <input placeholder="Tìm kiếm sự kiện..."></div><div class="nav-actions">${button("Tạo sự kiện", "outline", true)}${button("Đăng nhập", "secondary", true)}${button("Đăng ký", "primary", true)}</div></nav>`;
}

const navByRole = {
  ORGANIZER: [["▦", "Tổng quan"], ["◫", "Sự kiện"], ["▤", "Đơn hàng"], ["✓", "Check-in"], ["♙", "Nhân viên"], ["◒", "Báo cáo"]],
  STAFF: [["▦", "Lịch làm việc"], ["⌁", "Soát vé"]],
  ADMIN: [["▦", "Tổng quan"], ["◎", "Duyệt sự kiện"], ["◫", "Danh mục"], ["▤", "Đơn hàng"], ["♙", "Người dùng"]]
};

function portalShell(screen, content) {
  const role = screen.role;
  const nav = navByRole[role] || navByRole.ORGANIZER;
  const roleClass = role === "ADMIN" ? "admin" : role === "ORGANIZER" ? "organizer" : "";
  return `<div class="portal-shell ${state.collapsed ? "sidebar-collapsed" : ""}">
    <aside class="portal-sidebar ${roleClass}">
      <div class="brand"><span class="brand-mark">ϟ</span><span>WuangEvents</span></div>
      <div class="portal-nav-label">Điều hướng</div>
      ${nav.map(([icon, label], index) => `<div class="portal-link ${index === 0 ? "active" : ""}"><span class="icon">${icon}</span><span>${label}</span></div>`).join("")}
      <div class="portal-user"><span class="avatar">${role === "ADMIN" ? "AD" : role === "STAFF" ? "NV" : "TC"}</span><div><strong>${roles[role]}</strong><small>${role === "ADMIN" ? "admin@wuangevents.com" : "Đang hoạt động"}</small></div></div>
    </aside>
    <section class="portal-main"><header class="portal-header"><div><div class="crumb">WuangEvents / ${boards[screen.board]}</div><h1>${screen.title}</h1></div><div class="portal-header-actions">${button("Thông báo", "secondary", true)}<span class="avatar">NA</span></div></header><main class="portal-content">${content}</main></section>
  </div>`;
}

function publicShell(content) {
  return `<div class="public-shell">${publicNav()}<main class="public-body">${content}</main></div>`;
}

function heading(title, subtitle, actions = "") {
  return `<div class="page-heading"><div><h2>${title}</h2><p>${subtitle}</p></div><div>${actions}</div></div>`;
}

function screenContent(screen) {
  switch (screen.template) {
    case "design-system": return designSystem();
    case "state-gallery": return stateGallery();
    case "home": return home();
    case "event-list": return eventList();
    case "event-detail": return eventDetail();
    case "auth": return auth(screen.variant);
    case "profile": return profile();
    case "organizer-request": return organizerRequest();
    case "booking": return booking();
    case "checkout": return checkout();
    case "success": return success();
    case "customer-orders": return customerOrders();
    case "ticket-detail": return ticketDetail();
    case "organizer-dashboard": return organizerDashboard();
    case "event-management": return eventManagement();
    case "event-editor": return eventEditor();
    case "organizer-event-detail": return organizerEventDetail();
    case "ticket-types": return ticketTypes();
    case "discounts": return discounts();
    case "seat-map": return seatMap();
    case "organizer-orders": return organizerOrders();
    case "attendees": return attendees();
    case "checkin": return checkin(screen.variant);
    case "staff-assignment": return staffAssignment();
    case "staff-accounts": return staffAccounts();
    case "communications": return communications();
    case "reports": return reports();
    case "staff-schedule": return staffSchedule();
    case "admin-dashboard": return adminDashboard();
    case "admin-categories": return adminCategories();
    case "approval-queue": return approvalQueue(screen.variant);
    case "admin-orders": return adminOrders();
    case "admin-users": return adminUsers();
    default: return stateGallery();
  }
}

function designSystem() {
  return publicShell(`${heading("Nền tảng giao diện WuangEvents", "Token và primitive lấy từ frontend hiện tại")}
    ${kpis([["Primary", "#7C3AED", "Màu thương hiệu", "●"], ["Typography", "Inter", "Plus Jakarta Sans", "Aa"], ["Radius", "8–16px", "Phân cấp theo bề mặt", "⌒"], ["Motion", "200ms", "Phản hồi trực tiếp", "↝"]])}
    <div class="grid grid-2" style="margin-top:14px"><div class="card card-body"><h3>Button và badge</h3><div style="display:flex;gap:8px;flex-wrap:wrap;margin-top:14px">${button("Primary", "primary")}${button("Secondary", "secondary")}${button("Outline", "outline")}${badge("Hoạt động", "success")}${badge("Chờ duyệt", "warning")}${badge("Từ chối", "danger")}</div></div><div class="card card-body"><h3>Form control</h3><div class="toolbar" style="margin-top:12px">${field("Tìm kiếm...")}${field("Tất cả trạng thái", "select")}${button("Áp dụng", "primary", true)}</div></div></div>`);
}

function stateGallery() {
  return publicShell(`${heading("Trạng thái dùng chung", "Một hệ thống phản hồi thống nhất cho toàn bộ ứng dụng")}
    <div class="state-grid"><div class="state-card"><div><div class="state-icon">◌</div><h3>Đang tải</h3><p>Giữ nguyên bố cục trong lúc nhận dữ liệu.</p></div></div><div class="state-card"><div><div class="state-icon">⌕</div><h3>Chưa có dữ liệu</h3><p>Giải thích ngắn và chỉ dẫn hành động tiếp theo.</p></div></div><div class="state-card"><div><div class="state-icon">!</div><h3>Không thể tải dữ liệu</h3><p>Giữ ngữ cảnh và cho phép thử lại.</p></div></div><div class="state-card"><div><div class="state-icon">✓</div><h3>Thành công</h3><p>Thông báo rõ kết quả vừa hoàn tất.</p></div></div><div class="state-card"><div><div class="state-icon">⊘</div><h3>Không có quyền</h3><p>Không hiển thị hành động vượt phạm vi vai trò.</p></div></div><div class="state-card"><div style="width:100%"><div class="skeleton" style="height:14px;width:55%"></div><div class="skeleton" style="height:65px;margin-top:12px"></div><div class="skeleton" style="height:14px;width:76%;margin-top:12px"></div></div></div></div>`);
}

function home() {
  return publicShell(`<section class="hero"><div><span class="eyebrow" style="color:#ddd6fe">Sự kiện nổi bật tháng 8</span><h1>Chạm vào những trải nghiệm đáng nhớ</h1><p>Khám phá concert, hội thảo, thể thao và hoạt động cộng đồng trên khắp Việt Nam.</p>${button("Khám phá sự kiện", "secondary")}</div><div class="hero-art"></div></section><div style="margin-top:24px">${heading("Sự kiện HOT nổi bật", "Được quan tâm nhiều nhất tuần này", button("Xem tất cả", "quiet", true))}${eventCards(3)}</div>`);
}

function eventList() {
  return publicShell(`${heading("Khám phá sự kiện", "Tìm trải nghiệm phù hợp theo thời gian và địa điểm")}<div class="toolbar" style="margin-bottom:16px">${field("Tên sự kiện, nghệ sĩ...")}${field("Tất cả danh mục", "select")}${field("Tất cả thành phố", "select")}<span class="spacer"></span>${button("Xóa bộ lọc", "outline", true)}</div>${eventCards(6)}`);
}

function eventDetail() {
  return publicShell(`<section class="detail-hero"><div><span class="eyebrow" style="color:#ddd6fe">ÂM NHẠC & CONCERT</span><h1>Ben Thanh Concert · Phương Linh × Phan Mạnh Quỳnh</h1><div class="detail-facts"><span>◷ 20:00 · Thứ bảy, 18/08/2026</span><span>⌖ Nhà hát Thành phố Hồ Chí Minh</span><span>♙ Ban tổ chức Wuang Live</span></div></div><aside class="ticket-panel"><strong>Chọn loại vé</strong><div class="ticket-option"><span><b>Standard</b><small class="cell-sub">Còn 182 vé</small></span><b>450.000đ</b></div><div class="ticket-option"><span><b>VIP</b><small class="cell-sub">Còn 46 vé</small></span><b>950.000đ</b></div>${button("Chọn vé", "primary")}</aside></section><div class="grid grid-2" style="margin-top:16px"><div class="card card-body"><h3>Thông tin sự kiện</h3><p style="color:var(--muted);font-size:11px;line-height:1.7">Một đêm nhạc giàu cảm xúc với những ca khúc được yêu thích, không gian sân khấu trang trọng và hệ thống âm thanh chuyên nghiệp.</p></div><div class="card card-body"><h3>Địa điểm</h3><p style="color:var(--muted);font-size:11px">07 Công trường Lam Sơn, Quận 1, TP. Hồ Chí Minh</p></div></div>`);
}

function auth(variant) {
  const register = variant === "register";
  return `<div class="public-shell">${publicNav()}<div class="auth-layout"><section class="auth-art"><span class="eyebrow" style="color:#ddd6fe">WUANGEVENTS</span><h1>${register ? "Bắt đầu hành trình sự kiện của bạn" : "Chào mừng bạn trở lại"}</h1><p>${register ? "Theo dõi sự kiện yêu thích, quản lý vé và trở thành Ban tổ chức khi bạn sẵn sàng." : "Đăng nhập để xem vé, thanh toán đơn hàng và quản lý sự kiện của bạn."}</p></section><section class="auth-panel"><div class="auth-card"><h2>${register ? "Tạo tài khoản" : "Đăng nhập"}</h2><p style="color:var(--muted);font-size:11px">${register ? "Điền thông tin để bắt đầu" : "Sử dụng email đã đăng ký"}</p><div class="form-grid">${register ? `<div class="form-field"><label>Họ và tên</label><input value="Nguyễn Minh Anh"></div>` : ""}<div class="form-field"><label>Email</label><input value="minhanh@gmail.com"></div><div class="form-field"><label>Mật khẩu</label><input type="password" value="12345678"></div>${register ? `<label style="font-size:10px"><input type="checkbox"> Tôi muốn đăng ký làm Ban tổ chức</label>` : `<a style="color:var(--primary);font-size:10px;text-align:right">Quên mật khẩu?</a>`}${button(register ? "Đăng ký" : "Đăng nhập", "primary")}</div></div></section></div></div>`;
}

function profile() {
  return publicShell(`${heading("Hồ sơ cá nhân", "Cập nhật thông tin và bảo mật tài khoản")}${`<div class="master-detail"><div class="card card-body"><div class="form-grid"><div class="form-field"><label>Họ và tên</label><input value="Nguyễn Minh Anh"></div><div class="form-field"><label>Email</label><input value="minhanh@gmail.com" disabled></div><div class="form-field"><label>Số điện thoại</label><input value="0903 123 456"></div>${button("Lưu thay đổi", "primary")}</div></div><aside class="card card-body"><div class="avatar" style="width:76px;height:76px;font-size:20px">NA</div><h3>Nguyễn Minh Anh</h3><p style="color:var(--muted);font-size:10px">Khách hàng · Hoạt động</p><hr style="border:0;border-top:1px solid var(--border)"><h3>Đổi mật khẩu</h3>${button("Cập nhật mật khẩu", "outline", true)}</aside></div>`}`);
}

function organizerRequest() {
  return publicShell(`${heading("Trở thành Ban tổ chức", "Gửi yêu cầu để tạo và vận hành sự kiện trên WuangEvents")}${`<div class="master-detail"><div class="card card-body"><div class="form-grid"><div class="form-field"><label>Họ tên người đại diện</label><input value="Nguyễn Minh Anh"></div><div class="form-field"><label>Số điện thoại liên hệ</label><input value="0903 123 456"></div><div class="form-field"><label>Thông tin bổ sung</label><textarea placeholder="Mô tả loại sự kiện bạn dự kiến tổ chức"></textarea></div>${button("Gửi yêu cầu", "primary")}</div></div><aside class="card card-body"><h3>Quy trình xét duyệt</h3><div class="timeline" style="margin-top:16px"><div class="timeline-item"><b>Gửi thông tin</b><span class="cell-sub">Xác nhận người đại diện</span></div><div class="timeline-item"><b>Quản trị viên đánh giá</b><span class="cell-sub">Kiểm tra thông tin và lịch sử</span></div><div class="timeline-item"><b>Kích hoạt quyền</b><span class="cell-sub">Bắt đầu tạo sự kiện</span></div></div></aside></div>`}`);
}

function booking() {
  return publicShell(`${heading("Chọn vé", "Ben Thanh Concert 2026")}${`<div class="seat-layout"><div class="seat-canvas"><div class="stage">SÂN KHẤU</div><div class="seats">${Array.from({length:84}, (_, index) => `<span class="seat ${[18,19,31,44].includes(index) ? "selected" : index % 9 === 0 ? "sold" : ""}">${String.fromCharCode(65 + Math.floor(index / 12))}${index % 12 + 1}</span>`).join("")}</div></div><aside class="card"><div class="card-header"><h3>Đơn đang chọn</h3>${badge("4 ghế", "primary")}</div><div class="card-body stack"><div class="ticket-option"><span>A7 · A8</span><b>900.000đ</b></div><div class="ticket-option"><span>B8 · C9</span><b>900.000đ</b></div><div style="display:flex;justify-content:space-between"><b>Tạm tính</b><b>1.800.000đ</b></div>${button("Tiếp tục thanh toán", "primary")}</div></aside></div>`}`);
}

function checkout() {
  return publicShell(`${heading("Thanh toán", "Hoàn tất thông tin trong 15 phút để giữ vé")}${`<div class="master-detail"><div class="card card-body"><h3>Thông tin người mua</h3><div class="form-grid grid-2"><div class="form-field"><label>Họ và tên</label><input value="Nguyễn Minh Anh"></div><div class="form-field"><label>Số điện thoại</label><input value="0903 123 456"></div><div class="form-field" style="grid-column:1/-1"><label>Email nhận vé</label><input value="minhanh@gmail.com"></div></div><h3 style="margin-top:20px">Phương thức thanh toán</h3><div class="ticket-option"><span><b>VNPAY</b><small class="cell-sub">Thẻ ngân hàng và QR</small></span>●</div><div class="ticket-option"><span><b>MoMo</b><small class="cell-sub">Ví điện tử</small></span>○</div></div><aside class="card"><div class="card-header"><h3>Tóm tắt đơn</h3></div><div class="card-body stack"><span class="cell-main">Ben Thanh Concert 2026</span><div class="ticket-option"><span>4 vé VIP</span><b>1.800.000đ</b></div><div class="toolbar">${field("Nhập mã giảm giá")}${button("Áp dụng", "outline", true)}</div><div style="display:flex;justify-content:space-between"><b>Thanh toán</b><b style="color:var(--primary);font-size:18px">1.800.000đ</b></div>${button("Thanh toán an toàn", "primary")}</div></aside></div>`}`);
}

function success() {
  return publicShell(`<div class="state-card" style="max-width:720px;margin:42px auto;min-height:430px"><div><div class="state-icon" style="margin:auto;color:var(--success);background:var(--success-soft)">✓</div><h3 style="font-size:21px">Đặt vé thành công!</h3><p>Đơn WE260812-0482 đã thanh toán. Vé điện tử đã sẵn sàng trong tài khoản của bạn.</p><div style="display:flex;justify-content:center;gap:8px;margin-top:18px">${button("Xem vé của tôi", "primary")}${button("Tiếp tục khám phá", "outline")}</div></div></div>`);
}

function customerOrders() {
  const rows = orderRows.map(([code, event, qty, total, status, style]) => [`<span class="cell-main">${code}</span><span class="cell-sub">12/08/2026</span>`, event, qty, `<span class="num">${total}</span>`, badge(status, style), button("Xem vé", "outline", true)]);
  return publicShell(`${heading("Vé của tôi", "Theo dõi đơn hàng và sử dụng vé QR tại sự kiện")}${`<div class="toolbar" style="margin-bottom:14px">${field("Mã đơn hoặc tên sự kiện")}${field("Tất cả trạng thái", "select")}<span class="spacer"></span>${button("Xóa bộ lọc", "outline", true)}</div>${table(["Mã đơn", "Sự kiện", "Số vé", "Tổng tiền", "Trạng thái", ""], rows, ["19%","25%","9%","13%","15%","12%"], "Hiển thị 1–4 trên 4 đơn hàng")}`}`);
}

function ticketDetail() {
  return publicShell(`${heading("Chi tiết vé", "Đơn WE260812-0482 · Đã thanh toán", button("Tải vé", "outline"))}${`<div class="master-detail"><div class="card card-body qr-card"><div class="qr">${Array.from({length:49}, () => "<i></i>").join("")}</div><div><span class="eyebrow">VÉ VIP · A7</span><h2>Ben Thanh Concert 2026</h2><div class="detail-facts" style="color:var(--muted)"><span>◷ 20:00 · 18/08/2026</span><span>⌖ Nhà hát Thành phố</span><span>Mã vé: WE-TK-6F3A8D</span></div>${badge("Chưa check-in", "warning")}</div></div><aside class="card card-body"><h3>Lịch sử vé</h3><div class="timeline" style="margin-top:16px"><div class="timeline-item"><b>Đặt vé</b><span class="cell-sub">12/08/2026 · 14:32</span></div><div class="timeline-item"><b>Thanh toán thành công</b><span class="cell-sub">VNPAY · 14:36</span></div><div class="timeline-item"><b>Chờ check-in</b><span class="cell-sub">Mở cổng lúc 18:30</span></div></div></aside></div>`}`);
}

function organizerDashboard() {
  return `${heading("Tổng quan", "Dữ liệu hoạt động của các sự kiện bạn quản lý", button("+ Tạo sự kiện", "primary"))}${kpis([["Sự kiện đang bán", "4", "+1 trong tháng", "◫"], ["Vé đã bán", "3.248", "+12,4% so tháng trước", "◉"], ["Doanh thu", "1,42 tỷ", "+8,7% so tháng trước", "₫"], ["Chờ xử lý", "7", "3 đơn chưa thanh toán", "!"]])}<div class="grid grid-2" style="margin-top:14px"><div><div class="card-header card"><h3>Doanh thu 12 tuần</h3>${badge("Theo tuần", "primary")}</div>${bars()}</div><div class="card card-body"><h3>Tỷ lệ vé đã bán</h3><div style="display:flex;align-items:center;justify-content:space-around;margin-top:18px"><div class="donut"></div><div class="stack"><span><b>2.534</b><small class="cell-sub">Đã bán</small></span><span><b>714</b><small class="cell-sub">Còn lại</small></span></div></div></div></div>`;
}

function eventManagement() {
  const rows = eventRows.map(([name, category, date, status, style, sold]) => [`<span class="cell-main">${name}</span><span class="cell-sub">WE-EVT-${name.slice(0,3).toUpperCase()}</span>`, category, date, badge(status, style), sold, button("Chi tiết", "outline", true)]);
  return `${heading("Sự kiện của tôi", "Quản lý vòng đời từ bản nháp đến kết thúc", button("+ Tạo sự kiện", "primary"))}<div class="toolbar" style="margin-bottom:12px">${field("Tên hoặc mã sự kiện")}${field("Tất cả trạng thái", "select")}${field("Tất cả danh mục", "select")}<span class="spacer"></span>${button("Xóa bộ lọc", "outline", true)}</div>${table(["Sự kiện", "Danh mục", "Ngày bắt đầu", "Trạng thái", "Đã bán", ""], rows, ["31%","13%","15%","15%","10%","12%"], "Hiển thị 1–5 trên 12 sự kiện")}`;
}

function eventEditor() {
  return `${heading("Tạo sự kiện", "Hoàn thiện thông tin trước khi gửi duyệt", `${button("Lưu bản nháp", "outline")}${button("Gửi duyệt", "primary")}`)}<div class="master-detail"><div class="card card-body"><div class="form-grid grid-2"><div class="form-field" style="grid-column:1/-1"><label>Tên sự kiện</label><input value="Vietnam Creator Conference 2026"></div><div class="form-field"><label>Danh mục</label><select><option>Hội thảo & Giáo dục</option></select></div><div class="form-field"><label>Hình thức</label><select><option>Trực tiếp</option></select></div><div class="form-field"><label>Ngày bắt đầu</label><input value="24/09/2026 08:30"></div><div class="form-field"><label>Ngày kết thúc</label><input value="24/09/2026 17:00"></div><div class="form-field" style="grid-column:1/-1"><label>Mô tả ngắn</label><textarea>Ngày hội dành cho nhà sáng tạo nội dung, thương hiệu và cộng đồng công nghệ.</textarea></div></div></div><aside class="card card-body"><h3>Tiến độ hoàn thiện</h3><div class="timeline" style="margin-top:16px"><div class="timeline-item"><b>Thông tin cơ bản</b><span class="cell-sub">Đã hoàn thành</span></div><div class="timeline-item"><b>Địa điểm và lịch</b><span class="cell-sub">Đã hoàn thành</span></div><div class="timeline-item"><b>Vé và sơ đồ</b><span class="cell-sub">Cần bổ sung</span></div></div></aside></div>`;
}

function organizerEventDetail() {
  return `${heading("Ben Thanh Concert 2026", "Không gian điều hành sự kiện", `${button("Chỉnh sửa", "outline")}${button("Dừng bán vé", "danger")}`)}${kpis([["Trạng thái", "Đang bán", "Đã được duyệt", "✓"], ["Vé đã bán", "1.842", "78% tổng số vé", "◉"], ["Doanh thu", "842 triệu", "Trước hoàn tiền", "₫"], ["Check-in", "0", "Mở lúc 18:30", "⌁"]])}<div class="grid grid-3" style="margin-top:14px"><div class="card card-body"><h3>Thiết lập vé</h3><p class="cell-sub">4 loại vé · 2.350 vé</p>${button("Quản lý loại vé", "outline", true)}</div><div class="card card-body"><h3>Mã giảm giá</h3><p class="cell-sub">3 mã đang hoạt động</p>${button("Quản lý mã", "outline", true)}</div><div class="card card-body"><h3>Sơ đồ chỗ ngồi</h3><p class="cell-sub">8 khu vực · 2.120 ghế</p>${button("Mở sơ đồ", "outline", true)}</div></div>`;
}

function ticketTypes() {
  const rows = [["Standard", "450.000đ", "1.200", "846", "10", badge("Đang bán", "success")], ["VIP", "950.000đ", "500", "412", "4", badge("Đang bán", "success")], ["Couple", "1.600.000đ", "300", "196", "2", badge("Đang bán", "success")], ["Early Bird", "350.000đ", "350", "350", "2", badge("Hết vé", "muted")]];
  return `${heading("Loại vé", "Ben Thanh Concert 2026", button("+ Thêm loại vé", "primary"))}${table(["Tên loại vé", "Giá bán", "Tổng số", "Đã bán", "Giới hạn/đơn", "Trạng thái"], rows, ["24%","16%","13%","13%","15%","16%"], "Tổng cộng 4 loại vé")}`;
}

function discounts() {
  const rows = [["EARLY20", "Giảm 20%", "200.000đ", "100", "84", badge("Hoạt động", "success")], ["WELCOME50", "Giảm 50.000đ", "—", "500", "286", badge("Hoạt động", "success")], ["VIP100", "Giảm 100.000đ", "—", "50", "50", badge("Hết lượt", "muted")]];
  return `${heading("Mã giảm giá", "Thiết lập ưu đãi cho từng sự kiện", button("+ Tạo mã", "primary"))}<div class="toolbar" style="margin-bottom:12px">${field("Tìm mã giảm giá")}${field("Tất cả trạng thái", "select")}</div>${table(["Mã", "Giá trị", "Giảm tối đa", "Tổng lượt", "Đã dùng", "Trạng thái"], rows, ["16%","20%","16%","13%","13%","18%"], "Tổng cộng 3 mã giảm giá")}`;
}

function seatMap() {
  return `${heading("Sơ đồ chỗ ngồi", "Thiết lập khu vực, hàng và ghế cho Ben Thanh Concert", `${button("Xóa sơ đồ", "danger")}${button("Lưu sơ đồ", "primary")}`)}<div class="seat-layout"><div class="seat-canvas"><div class="stage">SÂN KHẤU</div><div class="seats">${Array.from({length:84}, (_, index) => `<span class="seat ${index % 13 === 0 ? "sold" : ""}">${String.fromCharCode(65 + Math.floor(index / 12))}${index % 12 + 1}</span>`).join("")}</div></div><aside class="card card-body"><h3>Thiết lập khu vực</h3><div class="form-grid"><div class="form-field"><label>Tên khu vực</label><input value="VIP Center"></div><div class="form-field"><label>Loại vé áp dụng</label><select><option>VIP · 950.000đ</option></select></div><div class="form-field"><label>Số hàng</label><input value="8"></div><div class="form-field"><label>Số ghế mỗi hàng</label><input value="12"></div>${button("Thêm khu vực", "primary")}</div></aside></div>`;
}

function organizerOrders() {
  const rows = orderRows.map(([code, event, qty, total, status, style]) => [code, "Nguyễn Minh Anh", qty, total, badge(status, style), "VNPAY", button("Xem", "outline", true)]);
  return `${heading("Đơn hàng", "Theo dõi giao dịch của các sự kiện")}${`<div class="toolbar" style="margin-bottom:12px">${field("Mã đơn, email người mua")}${field("Tất cả sự kiện", "select")}${field("Tất cả trạng thái", "select")}</div>${table(["Mã đơn", "Người mua", "Số vé", "Tổng tiền", "Trạng thái", "Thanh toán", ""], rows, ["17%","19%","9%","13%","14%","12%","9%"], "Hiển thị 1–4 trên 1.284 đơn")}`}`;
}

function attendees() {
  const rows = [["Nguyễn Minh Anh", "minhanh@gmail.com", "VIP · A7", "WE-TK-6F3A8D", badge("Chưa check-in", "warning")], ["Trần Quốc Huy", "huy@gmail.com", "VIP · A8", "WE-TK-7A38C1", badge("Đã check-in", "success")], ["Lê Thanh Hà", "ha@gmail.com", "Standard", "WE-TK-9B17F2", badge("Chưa check-in", "warning")], ["Phạm Gia Bảo", "bao@gmail.com", "Couple · B8", "WE-TK-10A8DD", badge("Đã check-in", "success")]];
  return `${heading("Khách tham dự", "Ben Thanh Concert 2026", button("Xuất CSV", "outline"))}<div class="toolbar" style="margin-bottom:12px">${field("Tên, email hoặc mã vé")}${field("Tất cả loại vé", "select")}${field("Tất cả trạng thái", "select")}</div>${table(["Người tham dự", "Email", "Vé / Ghế", "Mã vé", "Check-in"], rows, ["22%","24%","18%","18%","17%"], "Hiển thị 1–4 trên 1.842 người")}`;
}

function checkin(variant) {
  return `${heading(variant === "staff" ? "Soát vé" : "Check-in sự kiện", "Quét QR hoặc nhập mã vé để xác nhận", badge("Cổng đang mở", "success"))}<div class="master-detail"><div class="card card-body" style="min-height:430px;display:grid;place-items:center;text-align:center"><div><div class="state-icon" style="margin:auto;font-size:24px">⌁</div><h2>Đưa mã QR vào vùng quét</h2><p style="color:var(--muted);font-size:11px">Hoặc nhập mã vé thủ công</p><div class="toolbar" style="margin-top:16px">${field("WE-TK-...")}${button("Kiểm tra vé", "primary")}</div></div></div><aside class="card"><div class="card-header"><h3>Kết quả gần nhất</h3>${badge("Hợp lệ", "success")}</div><div class="card-body"><span class="cell-main">Trần Quốc Huy</span><span class="cell-sub">Vé VIP · Ghế A8</span><div class="timeline" style="margin-top:18px"><div class="timeline-item"><b>Thanh toán thành công</b><span class="cell-sub">12/08/2026</span></div><div class="timeline-item"><b>Check-in lúc 18:42</b><span class="cell-sub">Cổng A · Nhân viên Lê Phúc</span></div></div></div></aside></div>`;
}

function staffAssignment() {
  const rows = [["Lê Hoàng Phúc", "phuc.staff@gmail.com", "CheckIn", "Cổng A", badge("Đã phân công", "success")], ["Trần Minh Tú", "tu.staff@gmail.com", "CheckIn", "Cổng B", badge("Đã phân công", "success")], ["Phạm Hải Yến", "yen.staff@gmail.com", "CheckIn", "Chưa gán", badge("Chờ phân công", "warning")]];
  return `${heading("Phân công nhân viên", "Ben Thanh Concert 2026", button("+ Thêm nhân viên", "primary"))}${table(["Nhân viên", "Email", "Vai trò", "Vị trí", "Trạng thái"], rows, ["22%","26%","15%","17%","18%"], "Tổng cộng 3 nhân viên")}`;
}

function staffAccounts() {
  const rows = [["Lê Hoàng Phúc", "phuc.staff@gmail.com", "2 sự kiện", "18/06/2026", badge("Hoạt động", "success")], ["Trần Minh Tú", "tu.staff@gmail.com", "1 sự kiện", "25/06/2026", badge("Hoạt động", "success")], ["Phạm Hải Yến", "yen.staff@gmail.com", "0 sự kiện", "02/07/2026", badge("Hoạt động", "success")]];
  return `${heading("Tài khoản nhân viên", "Quản lý nhân viên do Ban tổ chức tạo", button("+ Tạo tài khoản", "primary"))}${table(["Họ tên", "Email", "Đang phân công", "Ngày tạo", "Trạng thái"], rows, ["22%","28%","18%","15%","16%"], "Tổng cộng 3 tài khoản")}`;
}

function communications() {
  return `${heading("Liên lạc người tham dự", "Gửi thông tin quan trọng theo từng sự kiện")}<div class="master-detail"><div class="card card-body"><div class="form-grid"><div class="form-field"><label>Sự kiện</label><select><option>Ben Thanh Concert 2026</option></select></div><div class="form-field"><label>Tiêu đề</label><input value="Hướng dẫn check-in và thời gian mở cổng"></div><div class="form-field"><label>Nội dung</label><textarea>Quý khách vui lòng chuẩn bị mã QR và có mặt trước giờ biểu diễn 30 phút.</textarea></div>${button("Gửi thông báo", "primary")}</div></div><aside class="card card-body"><h3>Đối tượng nhận</h3><div class="kpi-value">1.842</div><p class="cell-sub">Khách có vé đã thanh toán</p><hr style="border:0;border-top:1px solid var(--border)"><p style="font-size:10px;color:var(--muted)">Thông báo sẽ được gửi tới email đã dùng khi đặt vé.</p></aside></div>`;
}

function reports() {
  return `${heading("Báo cáo sự kiện", "Ben Thanh Concert 2026", button("Xuất báo cáo CSV", "outline"))}${kpis([["Doanh thu", "842 triệu", "+8,7%", "₫"], ["Vé đã bán", "1.842", "78% tổng vé", "◉"], ["Đã check-in", "1.476", "80,1%", "✓"], ["Voucher", "214", "11,6% đơn", "%"]])}<div class="grid grid-2" style="margin-top:14px"><div>${bars([45,57,68,60,76,82,91,88,95,87,93,98])}</div><div class="card card-body"><h3>Cơ cấu doanh thu</h3><div style="display:flex;align-items:center;justify-content:space-around;margin-top:20px"><div class="donut"></div><div class="stack"><span><b>VIP</b><small class="cell-sub">54%</small></span><span><b>Standard</b><small class="cell-sub">32%</small></span><span><b>Khác</b><small class="cell-sub">14%</small></span></div></div></div></div>`;
}

function staffSchedule() {
  const rows = [["Ben Thanh Concert 2026", "18/08/2026 · 18:00", "Nhà hát Thành phố", "Cổng A", badge("Sắp diễn ra", "primary")], ["Vietnam Game Connect", "24/08/2026 · 07:30", "SECC", "Cổng chính", badge("Sắp diễn ra", "primary")], ["Green Living Fair", "05/09/2026 · 08:00", "Thiso Mall", "Cổng B", badge("Đã phân công", "success")]];
  return `${heading("Lịch làm việc", "Các sự kiện bạn được phân công")}${table(["Sự kiện", "Thời gian", "Địa điểm", "Vị trí", "Trạng thái"], rows, ["27%","20%","22%","13%","17%"], "Tổng cộng 3 lịch phân công")}`;
}

function adminDashboard() {
  return `${heading("Tổng quan quản trị", "Tình trạng hoạt động toàn hệ thống")}${kpis([["Người dùng", "12.486", "+328 tháng này", "♙"], ["Ban tổ chức", "286", "12 chờ duyệt", "◎"], ["Sự kiện", "1.024", "18 chờ duyệt", "◫"], ["Doanh thu", "8,42 tỷ", "+14,2%", "₫"]])}<div class="grid grid-2" style="margin-top:14px"><div>${bars([52,60,68,74,66,83,79,90,85,94,91,98])}</div><div class="card card-body"><h3>Công việc cần xử lý</h3><div class="stack" style="margin-top:14px"><div class="ticket-option"><span>Yêu cầu Ban tổ chức</span>${badge("12", "warning")}</div><div class="ticket-option"><span>Sự kiện chờ duyệt</span>${badge("18", "warning")}</div><div class="ticket-option"><span>Giao dịch cần kiểm tra</span>${badge("4", "danger")}</div></div></div></div>`;
}

function adminCategories() {
  const rows = [["Âm nhạc & Concert", "fas fa-music", "0", badge("Hoạt động", "success")], ["Kịch nói & Nghệ thuật", "fas fa-theater-masks", "1", badge("Hoạt động", "success")], ["Hội thảo & Giáo dục", "fas fa-graduation-cap", "2", badge("Hoạt động", "success")], ["Thể thao & Giải trí", "fas fa-running", "3", badge("Hoạt động", "success")], ["Ẩm thực & Du lịch", "fas fa-utensils", "4", badge("Hoạt động", "success")]];
  return `${heading("Danh mục sự kiện", "Dữ liệu phân loại dùng trên trang khám phá", button("+ Thêm danh mục", "primary"))}${table(["Tên danh mục", "Biểu tượng", "Thứ tự", "Trạng thái"], rows, ["38%","28%","14%","19%"], "Hiển thị 1–5 trên 6 danh mục")}`;
}

function approvalQueue(variant) {
  const organizer = variant === "organizer";
  const rows = organizer
    ? [["Nguyễn Quốc Bảo", "bao.events@gmail.com", "0908 222 111", "14/07/2026", badge("Chờ duyệt", "warning")], ["Lê Thanh Hà", "ha.studio@gmail.com", "0912 776 234", "18/07/2026", badge("Chờ duyệt", "warning")], ["Trần Mỹ Linh", "linh.media@gmail.com", "0938 901 889", "20/07/2026", badge("Chờ duyệt", "warning")]]
    : eventRows.slice(1).map(([name, category, date, status, style]) => [name, "Wuang Partner", category, date, badge(status, style)]);
  return `${heading(organizer ? "Duyệt Ban tổ chức" : "Duyệt sự kiện", organizer ? "Kiểm tra yêu cầu nâng quyền tài khoản" : "Kiểm tra nội dung trước khi công khai")}${`<div class="master-detail"><div><div class="toolbar" style="margin-bottom:12px">${field("Tìm kiếm...")}${field("Chờ duyệt", "select")}</div>${table(organizer ? ["Người yêu cầu", "Email", "Điện thoại", "Ngày gửi", "Trạng thái"] : ["Sự kiện", "Ban tổ chức", "Danh mục", "Ngày bắt đầu", "Trạng thái"], rows, organizer ? ["24%","28%","17%","15%","15%"] : ["30%","22%","18%","15%","15%"], `Tổng cộng ${rows.length} yêu cầu`)}</div><aside class="card"><div class="card-header"><h3>Thông tin xét duyệt</h3>${badge("Chờ quyết định", "warning")}</div><div class="card-body stack"><span class="cell-main">${organizer ? "Nguyễn Quốc Bảo" : "Vietnam Game Connect"}</span><span class="cell-sub">${organizer ? "Đã xác nhận email · Tài khoản hoạt động" : "Sự kiện trực tiếp · SECC, TP.HCM"}</span><div class="form-field"><label>Ghi chú quyết định</label><textarea placeholder="Nhập lý do khi từ chối"></textarea></div><div style="display:flex;justify-content:flex-end;gap:8px">${button("Từ chối", "danger")}${button("Phê duyệt", "primary")}</div></div></aside></div>`}`;
}

function adminOrders() {
  const rows = orderRows.map(([code, event, qty, total, status, style]) => [code, "Nguyễn Minh Anh", event, total, "VNPAY", badge(status, style), button("Chi tiết", "outline", true)]);
  return `${heading("Đơn hàng toàn hệ thống", "Tra cứu giao dịch của mọi sự kiện")}${`<div class="toolbar" style="margin-bottom:12px">${field("Mã đơn, email, sự kiện")}${field("Tất cả trạng thái", "select")}${field("Tất cả phương thức", "select")}</div>${table(["Mã đơn", "Người mua", "Sự kiện", "Tổng tiền", "Phương thức", "Trạng thái", ""], rows, ["15%","17%","24%","12%","12%","12%","8%"], "Hiển thị 1–4 trên 8.426 đơn")}`}`;
}

function adminUsers() {
  const rows = userRows.map(([name, email, role, status, style]) => [`<span class="cell-main">${name}</span><span class="cell-sub">${email}</span>`, role, "12/06/2026", badge(status, style), button("Chi tiết", "outline", true)]);
  return `${heading("Người dùng", "Quản lý tài khoản và quyền truy cập", button("Xuất CSV", "outline"))}${`<div class="master-detail"><div><div class="toolbar" style="margin-bottom:12px">${field("Tên hoặc email")}${field("Tất cả vai trò", "select")}${field("Tất cả trạng thái", "select")}</div>${table(["Người dùng", "Vai trò", "Ngày tạo", "Trạng thái", ""], rows, ["34%","20%","16%","16%","12%"], "Hiển thị 1–5 trên 12.486 người dùng")}</div><aside class="card"><div class="card-header"><h3>Chi tiết người dùng</h3>${badge("Hoạt động", "success")}</div><div class="card-body stack"><div class="avatar" style="width:56px;height:56px">NA</div><span class="cell-main">Nguyễn Minh Anh</span><span class="cell-sub">minhanh@gmail.com · Khách hàng</span><hr style="border:0;border-top:1px solid var(--border)"><div><span class="cell-sub">Đơn hàng</span><b>12</b></div><div><span class="cell-sub">Tổng chi tiêu</span><b>6.420.000đ</b></div>${button("Khóa tài khoản", "danger")}</div></aside></div>`}`;
}

function screenMarkup(screen) {
  const content = screenContent(screen);
  const portal = ["ORGANIZER", "STAFF", "ADMIN"].includes(screen.role);
  return `<section class="screen" data-screen="${screen.id}" data-board="${screen.board}" data-role="${screen.role}">${portal ? portalShell(screen, content) : content}</section>`;
}

const state = { collapsed: false, compact: false };

function render() {
  const atlas = document.querySelector("#atlas");
  const board = document.querySelector("#boardFilter")?.value || query.get("board") || "all";
  const role = document.querySelector("#roleFilter")?.value || query.get("role") || "all";
  const screens = manifest.filter(screen => (!selectedScreen || screen.id === selectedScreen) && (board === "all" || screen.board === board) && (role === "all" || screen.role === role));
  atlas.innerHTML = screens.map(screen => `<article class="atlas-card"><header class="atlas-card-header"><div><span class="atlas-board-name">${screen.board} · ${boards[screen.board]}</span><strong>${screen.title}</strong><small>${screen.subtitle}</small></div><span class="atlas-index">${screen.board}.${String(screen.index).padStart(2,"0")}</span></header><div class="atlas-preview">${screenMarkup(screen)}</div><footer class="atlas-card-footer"><span>${roles[screen.role]} · ${screen.route || "Design contract"}</span><a href="?screen=${screen.id}&mode=render" target="_blank">Mở toàn màn hình ↗</a></footer></article>`).join("");
  document.querySelector("#screenCount").textContent = `${screens.length}/${manifest.length} màn hình`;
  document.body.classList.toggle("compact", state.compact);
  fitOverviewPreviews();
}

function fitOverviewPreviews() {
  if (renderMode) return;
  requestAnimationFrame(() => {
    document.querySelectorAll(".atlas-preview").forEach(preview => {
      const screen = preview.querySelector(":scope > .screen");
      if (!screen || preview.clientWidth <= 0) return;
      const scale = preview.clientWidth / previewCanvas.width;
      preview.style.height = `${previewCanvas.height * scale}px`;
      screen.style.transform = `scale(${scale})`;
    });
  });
}

function setupFilters() {
  const boardFilter = document.querySelector("#boardFilter");
  Object.entries(boards).forEach(([code, label]) => boardFilter.insertAdjacentHTML("beforeend", `<option value="${code}">${code} · ${label}</option>`));
  const roleFilter = document.querySelector("#roleFilter");
  Object.entries(roles).forEach(([code, label]) => roleFilter.insertAdjacentHTML("beforeend", `<option value="${code}">${label}</option>`));
  if (query.get("board")) boardFilter.value = query.get("board");
  if (query.get("role")) roleFilter.value = query.get("role");
  boardFilter.addEventListener("change", render);
  roleFilter.addEventListener("change", render);
  document.querySelector("#densityToggle").addEventListener("click", () => { state.compact = !state.compact; render(); });
  document.querySelector("#sidebarToggle").addEventListener("click", () => { state.collapsed = !state.collapsed; render(); });
}

if (renderMode) document.body.classList.add("render-mode");
setupFilters();
render();

if (!renderMode) {
  const observer = new ResizeObserver(fitOverviewPreviews);
  observer.observe(document.querySelector("#atlas"));
  window.addEventListener("resize", fitOverviewPreviews, { passive: true });
}
