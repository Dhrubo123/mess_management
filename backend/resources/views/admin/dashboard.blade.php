<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>MessMate BD — Company Admin Dashboard</title>
    <link rel="icon" type="image/svg+xml" href="/favicon.svg?v=2">
    <script src="https://cdn.tailwindcss.com"></script>
</head>
<body class="bg-[#F5F7F6] text-slate-900 font-sans">
    <!-- Top Navbar -->
    <header class="bg-[#063D30] text-white sticky top-0 z-20 shadow">
        <div class="max-w-7xl mx-auto px-4 sm:px-6 py-3.5 flex items-center justify-between">
            <div class="flex items-center gap-3">
                <div class="w-9 h-9 rounded-xl bg-white/15 flex items-center justify-center font-black">M</div>
                <div>
                    <div class="font-extrabold text-base leading-tight">MessMate BD — Company Admin</div>
                    <div class="text-xs text-emerald-200">Chattogram Operations, Sponsors & Boost Revenue</div>
                </div>
            </div>
            <div class="flex items-center gap-4">
                <span class="hidden sm:inline text-xs text-emerald-100">{{ auth()->user()->email }}</span>
                <form method="POST" action="{{ route('admin.logout') }}">
                    @csrf
                    <button class="px-3.5 py-1.5 rounded-lg bg-white/10 hover:bg-white/20 text-xs font-semibold">Sign Out</button>
                </form>
            </div>
        </div>
    </header>

    <main class="max-w-7xl mx-auto px-4 sm:px-6 py-6 space-y-6">
        @if (session('status'))
            <div class="p-3.5 rounded-xl bg-emerald-50 border border-emerald-200 text-emerald-900 text-sm font-semibold">
                {{ session('status') }}
            </div>
        @endif

        <!-- KPI Row -->
        <section class="grid grid-cols-2 lg:grid-cols-6 gap-4">
            <div class="bg-white p-4 rounded-2xl border border-slate-200">
                <div class="text-xs text-slate-500 font-semibold">Total Users</div>
                <div class="text-2xl font-extrabold mt-1">{{ $stats['users'] }}</div>
            </div>
            <div class="bg-white p-4 rounded-2xl border border-slate-200">
                <div class="text-xs text-slate-500 font-semibold">Active Messes</div>
                <div class="text-2xl font-extrabold mt-1 text-[#0A5C48]">{{ $stats['messes'] }}</div>
            </div>
            <div class="bg-white p-4 rounded-2xl border border-slate-200">
                <div class="text-xs text-slate-500 font-semibold">Active To-Let Seats</div>
                <div class="text-2xl font-extrabold mt-1">{{ $stats['active_listings'] }}</div>
            </div>
            <div class="bg-white p-4 rounded-2xl border border-slate-200">
                <div class="text-xs text-slate-500 font-semibold">Active Sponsors</div>
                <div class="text-2xl font-extrabold mt-1 text-indigo-700">{{ $stats['active_banners'] }}</div>
            </div>
            <div class="bg-white p-4 rounded-2xl border border-amber-200 bg-amber-50/40">
                <div class="text-xs text-amber-700 font-semibold">Pending Boosts</div>
                <div class="text-2xl font-extrabold mt-1 text-amber-700">{{ $stats['pending_boosts'] }}</div>
            </div>
            <div class="bg-white p-4 rounded-2xl border border-emerald-200 bg-emerald-50/40">
                <div class="text-xs text-emerald-700 font-semibold">Boost Revenue</div>
                <div class="text-2xl font-extrabold mt-1 text-emerald-800">৳{{ number_format($stats['boost_revenue'], 0) }}</div>
            </div>
        </section>

        <!-- Row 2: Pending Seat Boosts + CTG Area Clusters -->
        <section class="grid grid-cols-1 lg:grid-cols-3 gap-6">
            <!-- Boost Requests -->
            <div class="lg:col-span-2 bg-white rounded-2xl border border-slate-200 p-5">
                <div class="flex items-center justify-between mb-4">
                    <div>
                        <h2 class="font-extrabold text-base">৳99 Seat Boost Requests (bKash / Nagad)</h2>
                        <p class="text-xs text-slate-500">Verify TrxID and approve to pin the seat as Featured for 7 days.</p>
                    </div>
                </div>
                <div class="overflow-x-auto">
                    <table class="w-full text-sm">
                        <thead>
                            <tr class="text-left text-xs text-slate-500 border-b border-slate-100">
                                <th class="pb-2">Seat Listing</th>
                                <th class="pb-2">Payment</th>
                                <th class="pb-2">Status</th>
                                <th class="pb-2 text-right">Action</th>
                            </tr>
                        </thead>
                        <tbody class="divide-y divide-slate-100">
                            @forelse ($boostRequests as $b)
                                <tr>
                                    <td class="py-3 pr-3">
                                        <div class="font-bold text-slate-800">{{ $b->seatListing?->title ?? 'Deleted Listing' }}</div>
                                        <div class="text-xs text-slate-500">{{ $b->seatListing?->area }} • By {{ $b->user?->name }} ({{ $b->sender_phone }})</div>
                                    </td>
                                    <td class="py-3 pr-3">
                                        <span class="inline-block px-2 py-0.5 rounded text-xs font-bold uppercase {{ $b->payment_method === 'bkash' ? 'bg-pink-100 text-pink-700' : 'bg-orange-100 text-orange-700' }}">
                                            {{ $b->payment_method }}
                                        </span>
                                        <div class="font-mono text-xs font-bold mt-1">{{ $b->trx_id }}</div>
                                        <div class="text-xs text-slate-500">৳{{ number_format($b->amount, 0) }}</div>
                                    </td>
                                    <td class="py-3 pr-3">
                                        <span class="px-2.5 py-1 rounded-full text-xs font-bold
                                            {{ $b->status === 'approved' ? 'bg-emerald-100 text-emerald-800' : ($b->status === 'rejected' ? 'bg-red-100 text-red-700' : 'bg-amber-100 text-amber-800') }}">
                                            {{ ucfirst($b->status) }}
                                        </span>
                                    </td>
                                    <td class="py-3 text-right whitespace-nowrap">
                                        @if ($b->status === 'pending')
                                            <form method="POST" action="{{ route('admin.boosts.approve', $b) }}" class="inline">
                                                @csrf
                                                <button class="px-3 py-1.5 rounded-lg bg-[#0A5C48] text-white text-xs font-bold hover:bg-[#063D30]">Approve</button>
                                            </form>
                                            <form method="POST" action="{{ route('admin.boosts.reject', $b) }}" class="inline ml-1">
                                                @csrf
                                                <button class="px-2.5 py-1.5 rounded-lg bg-red-50 text-red-700 text-xs font-bold hover:bg-red-100">Reject</button>
                                            </form>
                                        @else
                                            <span class="text-xs text-slate-400">Reviewed</span>
                                        @endif
                                    </td>
                                </tr>
                            @empty
                                <tr><td colspan="4" class="py-6 text-center text-slate-400 text-xs">No boost requests yet.</td></tr>
                            @endforelse
                        </tbody>
                    </table>
                </div>
            </div>

            <!-- Chattogram Area Clusters -->
            <div class="bg-white rounded-2xl border border-slate-200 p-5">
                <h2 class="font-extrabold text-base">Chattogram Mess Clusters</h2>
                <p class="text-xs text-slate-500 mb-4">Use this to choose where to launch Khatunganj Bazar delivery.</p>
                <div class="space-y-2.5">
                    @forelse ($areaClusters as $cluster)
                        <div class="flex items-center justify-between p-3 rounded-xl bg-slate-50 border border-slate-100">
                            <div>
                                <div class="font-bold text-sm">{{ $cluster->area }}</div>
                                <div class="text-xs text-slate-500">{{ $cluster->city }}</div>
                            </div>
                            <span class="px-3 py-1 rounded-full bg-emerald-100 text-emerald-800 font-extrabold text-xs">
                                {{ $cluster->mess_count }} {{ $cluster->mess_count === 1 ? 'Mess' : 'Messes' }}
                            </span>
                        </div>
                    @empty
                        <p class="text-xs text-slate-400">No messes registered yet.</p>
                    @endforelse
                </div>
            </div>
        </section>

        <!-- Row 3: Local CTG Sponsor Banners Manager -->
        <section class="grid grid-cols-1 lg:grid-cols-3 gap-6">
            <div class="bg-white rounded-2xl border border-slate-200 p-5">
                <h2 class="font-extrabold text-base mb-1">Publish Local CTG Sponsor</h2>
                <p class="text-xs text-slate-500 mb-4">Coaching centers, ISPs, tiffin services — appears live in the app.</p>
                <form method="POST" action="{{ route('admin.banners.store') }}" class="space-y-3">
                    @csrf
                    <input name="sponsor_name" placeholder="Sponsor Name (e.g. Chawk Bazar IELTS Care)" required
                        class="w-full px-3.5 py-2.5 rounded-xl border border-slate-200 text-sm">
                    <input name="headline" placeholder="Headline (e.g. 20% Off for MessMate Students)" required
                        class="w-full px-3.5 py-2.5 rounded-xl border border-slate-200 text-sm">
                    <input name="subtitle" placeholder="Short details (optional)"
                        class="w-full px-3.5 py-2.5 rounded-xl border border-slate-200 text-sm">
                    <div class="grid grid-cols-2 gap-2">
                        <input name="cta_label" value="Call Now" placeholder="Button Label"
                            class="px-3.5 py-2.5 rounded-xl border border-slate-200 text-sm">
                        <input name="cta_value" placeholder="018XXXXXXXX" required
                            class="px-3.5 py-2.5 rounded-xl border border-slate-200 text-sm">
                    </div>
                    <input name="target_area" placeholder="Target Area (leave blank for All CTG)"
                        class="w-full px-3.5 py-2.5 rounded-xl border border-slate-200 text-sm">
                    <button type="submit" class="w-full py-2.5 rounded-xl bg-[#0A5C48] hover:bg-[#063D30] text-white font-bold text-sm">
                        Publish Banner Live
                    </button>
                </form>
            </div>

            <div class="lg:col-span-2 bg-white rounded-2xl border border-slate-200 p-5">
                <h2 class="font-extrabold text-base mb-3">Active & Paused Sponsor Banners</h2>
                <div class="space-y-3">
                    @forelse ($banners as $banner)
                        <div class="p-4 rounded-xl border border-slate-200 flex flex-col sm:flex-row sm:items-center justify-between gap-3">
                            <div>
                                <div class="flex items-center gap-2">
                                    <span class="px-2 py-0.5 rounded bg-indigo-50 text-indigo-700 text-[10px] font-extrabold">{{ $banner->sponsor_name }}</span>
                                    <span class="text-xs text-slate-400">{{ $banner->target_area ?: 'All Chattogram' }}</span>
                                </div>
                                <div class="font-bold text-sm mt-1">{{ $banner->headline }}</div>
                                @if ($banner->subtitle)
                                    <div class="text-xs text-slate-500">{{ $banner->subtitle }}</div>
                                @endif
                                <div class="text-xs text-emerald-700 font-semibold mt-1">{{ $banner->cta_label }}: {{ $banner->cta_value }}</div>
                            </div>
                            <div class="flex items-center gap-2 shrink-0">
                                <form method="POST" action="{{ route('admin.banners.toggle', $banner) }}">
                                    @csrf
                                    <button class="px-3 py-1.5 rounded-lg text-xs font-bold {{ $banner->is_active ? 'bg-emerald-100 text-emerald-800' : 'bg-slate-100 text-slate-600' }}">
                                        {{ $banner->is_active ? 'Active' : 'Paused' }}
                                    </button>
                                </form>
                                <form method="POST" action="{{ route('admin.banners.destroy', $banner) }}">
                                    @csrf @method('DELETE')
                                    <button class="px-2.5 py-1.5 rounded-lg bg-red-50 text-red-700 text-xs font-bold">Delete</button>
                                </form>
                            </div>
                        </div>
                    @empty
                        <p class="text-xs text-slate-400">No sponsor banners yet.</p>
                    @endforelse
                </div>
            </div>
        </section>

        <!-- Row 4: To-Let Moderation & Registered Messes -->
        <section class="grid grid-cols-1 lg:grid-cols-2 gap-6">
            <div class="bg-white rounded-2xl border border-slate-200 p-5">
                <h2 class="font-extrabold text-base mb-3">To-Let Seat Moderation</h2>
                <div class="space-y-2.5">
                    @foreach ($listings as $l)
                        <div class="p-3.5 rounded-xl border border-slate-100 bg-slate-50/70 flex items-center justify-between gap-3">
                            <div>
                                <div class="font-bold text-sm">{{ $l->title }}</div>
                                <div class="text-xs text-slate-500">{{ $l->area }} • ৳{{ number_format($l->monthly_rent, 0) }}/mo • {{ $l->contact_phone }}</div>
                            </div>
                            <div class="flex items-center gap-1.5 shrink-0">
                                <form method="POST" action="{{ route('admin.listings.toggle-featured', $l) }}">
                                    @csrf
                                    <button class="px-2.5 py-1 rounded-lg text-xs font-bold {{ $l->is_featured ? 'bg-amber-100 text-amber-800' : 'bg-white border border-slate-200 text-slate-600' }}">
                                        {{ $l->is_featured ? 'Featured' : 'Pin' }}
                                    </button>
                                </form>
                                <form method="POST" action="{{ route('admin.listings.destroy', $l) }}">
                                    @csrf @method('DELETE')
                                    <button class="px-2.5 py-1 rounded-lg bg-red-50 text-red-700 text-xs font-bold">Remove</button>
                                </form>
                            </div>
                        </div>
                    @endforeach
                </div>
            </div>

            <div class="bg-white rounded-2xl border border-slate-200 p-5">
                <h2 class="font-extrabold text-base mb-3">Registered Messes</h2>
                <div class="space-y-2.5">
                    @foreach ($messes as $m)
                        <div class="p-3.5 rounded-xl border border-slate-100 bg-slate-50/70 flex items-center justify-between gap-3">
                            <div>
                                <div class="font-bold text-sm">{{ $m->name }}</div>
                                <div class="text-xs text-slate-500">{{ $m->area }}, {{ $m->city }} • Code: <span class="font-mono font-bold">{{ $m->invite_code }}</span></div>
                            </div>
                            <span class="px-2.5 py-1 rounded-full bg-emerald-100 text-emerald-800 text-xs font-bold">
                                {{ $m->active_members_count }} members
                            </span>
                        </div>
                    @endforeach
                </div>
            </div>
        </section>
    </main>
</body>
</html>
