// Toast, xác nhận và phản hồi giao diện dùng chung cho toàn website.
(function () {
    const settings = {
        success: { icon: 'fa-circle-check', title: 'Thành công' },
        error: { icon: 'fa-circle-xmark', title: 'Không thể thực hiện' },
        warning: { icon: 'fa-triangle-exclamation', title: 'Cần kiểm tra' },
        info: { icon: 'fa-circle-info', title: 'Thông báo' }
    };

    function cleanMessage(message) {
        return String(message ?? '').replace(/^(lỗi|cảnh báo|thông báo)\s*:\s*/i, '').trim();
    }

    function inferType(message) {
        const value = String(message ?? '').toLowerCase();
        return /lỗi|không thể|không hợp lệ|thất bại|vui lòng|tối đa|đã hết/.test(value)
            ? 'error'
            : 'info';
    }

    function toast(message, type = 'info', duration = 4600) {
        const content = cleanMessage(message);
        if (!content) return;

        const region = document.getElementById('uiToastRegion');
        if (!region) {
            window.addEventListener('DOMContentLoaded', () => toast(content, type, duration), { once: true });
            return;
        }

        const current = settings[type] || settings.info;
        const item = document.createElement('div');
        item.className = `ui-toast ui-toast-${type}`;
        item.setAttribute('role', type === 'error' ? 'alert' : 'status');
        item.innerHTML = `
            <div class="ui-toast-icon"><i class="fas ${current.icon}"></i></div>
            <div class="ui-toast-content"><strong>${current.title}</strong><span></span></div>
            <button type="button" class="ui-toast-close" aria-label="Đóng"><i class="fas fa-xmark"></i></button>
            <div class="ui-toast-progress"></div>`;
        item.querySelector('.ui-toast-content span').textContent = content;
        item.querySelector('.ui-toast-progress').style.animationDuration = `${duration}ms`;

        const close = () => {
            if (item.classList.contains('is-leaving')) return;
            item.classList.add('is-leaving');
            window.setTimeout(() => item.remove(), 220);
        };
        item.querySelector('.ui-toast-close').addEventListener('click', close);
        region.appendChild(item);
        window.setTimeout(close, duration);
    }

    function confirmAction(message, options = {}) {
        const dialog = document.getElementById('uiConfirmDialog');
        if (!dialog) return Promise.resolve(false);

        const title = document.getElementById('uiConfirmTitle');
        const body = document.getElementById('uiConfirmMessage');
        const submit = document.getElementById('uiConfirmSubmit');
        const cancel = document.getElementById('uiConfirmCancel');
        const icon = document.getElementById('uiConfirmIcon');
        const danger = options.danger !== false;

        title.textContent = options.title || 'Xác nhận thao tác';
        body.textContent = cleanMessage(message);
        submit.textContent = options.confirmText || 'Xác nhận';
        cancel.textContent = options.cancelText || 'Quay lại';
        submit.classList.toggle('is-danger', danger);
        icon.classList.toggle('is-danger', danger);
        dialog.classList.add('is-open');
        dialog.setAttribute('aria-hidden', 'false');

        return new Promise(resolve => {
            const finish = result => {
                dialog.classList.remove('is-open');
                dialog.setAttribute('aria-hidden', 'true');
                submit.removeEventListener('click', approve);
                cancel.removeEventListener('click', reject);
                dialog.removeEventListener('click', outside);
                document.removeEventListener('keydown', keyboard);
                resolve(result);
            };
            const approve = () => finish(true);
            const reject = () => finish(false);
            const outside = event => { if (event.target === dialog) reject(); };
            const keyboard = event => { if (event.key === 'Escape') reject(); };

            submit.addEventListener('click', approve);
            cancel.addEventListener('click', reject);
            dialog.addEventListener('click', outside);
            document.addEventListener('keydown', keyboard);
            window.setTimeout(() => cancel.focus(), 30);
        });
    }

    window.WuangUI = { toast, confirm: confirmAction };
    window.alert = message => toast(message, inferType(message));

    document.addEventListener('DOMContentLoaded', function () {
        const flash = document.getElementById('uiFlashData');
        if (flash) {
            ['success', 'error', 'warning', 'info'].forEach(type => {
                if (flash.dataset[type]) toast(flash.dataset[type], type);
            });
        }

        document.querySelectorAll('[data-ui-toast]').forEach(element => {
            toast(element.dataset.uiToast, element.dataset.uiToastType || 'info');
            element.remove();
        });
    });

    document.addEventListener('submit', async function (event) {
        const form = event.target.closest('form[data-confirm]');
        if (!form) return;
        if (form.dataset.uiConfirmed === 'true') {
            delete form.dataset.uiConfirmed;
            return;
        }

        event.preventDefault();
        const approved = await confirmAction(form.dataset.confirm, {
            title: form.dataset.confirmTitle || 'Xác nhận thao tác',
            confirmText: form.dataset.confirmButton || 'Xác nhận',
            danger: form.dataset.confirmTone !== 'normal'
        });
        if (!approved) return;

        form.dataset.uiConfirmed = 'true';
        if (form.requestSubmit) form.requestSubmit(event.submitter || undefined);
        else form.submit();
    }, true);
})();
