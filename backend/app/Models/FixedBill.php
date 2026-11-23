<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class FixedBill extends Model
{
    protected $fillable = [
        'mess_month_id',
        'title',
        'category',
        'total_amount',
        'split_type',
        'notes',
        'created_by',
    ];

    protected function casts(): array
    {
        return [
            'total_amount' => 'float',
        ];
    }

    public function messMonth(): BelongsTo
    {
        return $this->belongsTo(MessMonth::class);
    }

    public function creator(): BelongsTo
    {
        return $this->belongsTo(User::class, 'created_by');
    }
}
