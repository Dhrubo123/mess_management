<?php

use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\BazarController;
use App\Http\Controllers\Api\DepositController;
use App\Http\Controllers\Api\FixedBillController;
use App\Http\Controllers\Api\MealController;
use App\Http\Controllers\Api\MessController;
use App\Http\Controllers\Api\MonetizationController;
use App\Http\Controllers\Api\SeatListingController;
use App\Http\Controllers\Api\SummaryController;
use Illuminate\Support\Facades\Route;

// Public health & auth routes
Route::get('/health', fn () => response()->json(['status' => 'ok', 'app' => 'MessMate BD API']));
Route::post('/auth/register', [AuthController::class, 'register']);
Route::post('/auth/login', [AuthController::class, 'login']);

// Public Bachelor Seat / To-Let browse & Local Sponsor Banners
Route::get('/seat-listings', [SeatListingController::class, 'index']);
Route::get('/seat-listings/{seatListing}', [SeatListingController::class, 'show']);
Route::get('/sponsor-banners', [MonetizationController::class, 'banners']);

// Authenticated routes
Route::middleware('auth:sanctum')->group(function () {
    Route::get('/auth/me', [AuthController::class, 'me']);
    Route::patch('/auth/profile', [AuthController::class, 'updateProfile']);
    Route::post('/auth/logout', [AuthController::class, 'logout']);

    // Mess management
    Route::get('/messes', [MessController::class, 'index']);
    Route::post('/messes', [MessController::class, 'store']);
    Route::post('/messes/join', [MessController::class, 'join']);
    Route::get('/messes/{mess}', [MessController::class, 'show']);
    Route::patch('/messes/{mess}/settings', [MessController::class, 'updateSettings']);
    Route::post('/messes/{mess}/handover', [MessController::class, 'handoverManager']);

    // Monthly Summary, Month Lock & WhatsApp/Messenger Share
    Route::get('/messes/{mess}/summary', [SummaryController::class, 'monthly']);
    Route::get('/messes/{mess}/share-text', [SummaryController::class, 'shareText']);
    Route::post('/messes/{mess}/months/close', [SummaryController::class, 'closeMonth']);
    Route::post('/messes/{mess}/months/reopen', [SummaryController::class, 'reopenMonth']);

    // Meals
    Route::get('/messes/{mess}/meals', [MealController::class, 'index']);
    Route::post('/messes/{mess}/meals', [MealController::class, 'upsert']);
    Route::post('/messes/{mess}/meals/bulk', [MealController::class, 'bulkUpsert']);

    // Bazar expenses
    Route::get('/messes/{mess}/bazars', [BazarController::class, 'index']);
    Route::post('/messes/{mess}/bazars', [BazarController::class, 'store']);
    Route::delete('/messes/{mess}/bazars/{bazar}', [BazarController::class, 'destroy']);

    // Deposits
    Route::get('/messes/{mess}/deposits', [DepositController::class, 'index']);
    Route::post('/messes/{mess}/deposits', [DepositController::class, 'store']);
    Route::delete('/messes/{mess}/deposits/{deposit}', [DepositController::class, 'destroy']);

    // Fixed bills
    Route::get('/messes/{mess}/fixed-bills', [FixedBillController::class, 'index']);
    Route::post('/messes/{mess}/fixed-bills', [FixedBillController::class, 'store']);
    Route::delete('/messes/{mess}/fixed-bills/{fixedBill}', [FixedBillController::class, 'destroy']);

    // Bachelor Seat / To-Let management
    Route::get('/my-seat-listings', [SeatListingController::class, 'myListings']);
    Route::post('/seat-listings', [SeatListingController::class, 'store']);
    Route::post('/seat-listings/{seatListing}/boost', [MonetizationController::class, 'requestBoost']);
    Route::patch('/seat-listings/{seatListing}', [SeatListingController::class, 'update']);
    Route::delete('/seat-listings/{seatListing}', [SeatListingController::class, 'destroy']);
});
