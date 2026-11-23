<?php

use App\Http\Controllers\Admin\AdminController;
use Illuminate\Support\Facades\Route;

Route::get('/', fn () => redirect()->route('admin.dashboard'));

Route::prefix('admin')->name('admin.')->group(function () {
    Route::get('/login', [AdminController::class, 'showLogin'])->name('login');
    Route::post('/login', [AdminController::class, 'login'])->name('login.submit');
    Route::post('/logout', [AdminController::class, 'logout'])->name('logout');

    Route::get('/', [AdminController::class, 'dashboard'])->name('dashboard');

    Route::post('/banners', [AdminController::class, 'storeBanner'])->name('banners.store');
    Route::post('/banners/{sponsorBanner}/toggle', [AdminController::class, 'toggleBanner'])->name('banners.toggle');
    Route::delete('/banners/{sponsorBanner}', [AdminController::class, 'destroyBanner'])->name('banners.destroy');

    Route::post('/boosts/{boostRequest}/approve', [AdminController::class, 'approveBoost'])->name('boosts.approve');
    Route::post('/boosts/{boostRequest}/reject', [AdminController::class, 'rejectBoost'])->name('boosts.reject');

    Route::post('/listings/{seatListing}/toggle-featured', [AdminController::class, 'toggleFeaturedListing'])->name('listings.toggle-featured');
    Route::delete('/listings/{seatListing}', [AdminController::class, 'destroyListing'])->name('listings.destroy');
});
