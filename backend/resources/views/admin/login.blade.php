<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>MessMate BD — Company Admin Login</title>
    <link rel="icon" type="image/svg+xml" href="/favicon.svg?v=2">
    <script src="https://cdn.tailwindcss.com"></script>
</head>
<body class="min-h-screen bg-[#063D30] flex items-center justify-center p-4 font-sans">
    <div class="w-full max-w-md bg-white rounded-3xl shadow-2xl p-8">
        <div class="flex items-center gap-3 mb-6">
            <div class="w-11 h-11 rounded-2xl bg-[#0A5C48] text-white flex items-center justify-center font-black text-xl">M</div>
            <div>
                <h1 class="text-xl font-extrabold text-slate-900">MessMate BD</h1>
                <p class="text-xs text-slate-500 font-medium">Company Admin Panel • Chattogram</p>
            </div>
        </div>

        @if ($errors->any())
            <div class="mb-4 p-3 rounded-xl bg-red-50 border border-red-200 text-red-700 text-sm">
                {{ $errors->first() }}
            </div>
        @endif

        <form method="POST" action="{{ route('admin.login.submit') }}" class="space-y-4">
            @csrf
            <div>
                <label class="block text-xs font-semibold text-slate-700 mb-1">Admin Email</label>
                <input type="email" name="email" value="{{ old('email', 'admin@messmate.bd') }}" required
                    class="w-full px-4 py-3 rounded-xl border border-slate-200 focus:outline-none focus:ring-2 focus:ring-emerald-600 text-sm">
            </div>
            <div>
                <label class="block text-xs font-semibold text-slate-700 mb-1">Password</label>
                <input type="password" name="password" value="admin123" required
                    class="w-full px-4 py-3 rounded-xl border border-slate-200 focus:outline-none focus:ring-2 focus:ring-emerald-600 text-sm">
            </div>
            <button type="submit"
                class="w-full py-3 rounded-xl bg-[#0A5C48] hover:bg-[#063D30] text-white font-bold text-sm transition">
                Sign In to Company Admin
            </button>
        </form>

        <p class="mt-5 text-center text-xs text-slate-400">
            Default local admin: <span class="font-mono text-slate-600">admin@messmate.bd</span> / <span class="font-mono text-slate-600">admin123</span>
        </p>
    </div>
</body>
</html>
