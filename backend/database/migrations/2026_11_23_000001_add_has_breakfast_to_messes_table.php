<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('messes', function (Blueprint $table) {
            $table->boolean('has_breakfast')->default(false)->after('meal_cutoff_time');
        });
    }

    public function down(): void
    {
        Schema::table('messes', function (Blueprint $table) {
            $table->dropColumn('has_breakfast');
        });
    }
};
