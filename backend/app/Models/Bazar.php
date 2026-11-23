<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class Bazar extends Model
{
    protected $fillable = [
        'mess_month_id',
        'bought_by',
        'bazar_date',
        'amount',
        'items_note',
        'receipt_path',
        'created_by',
    ];

    protected $appends = ['receipt_url'];

    protected function casts(): array
    {
        return [
            'bazar_date' => 'date:Y-m-d',
            'amount' => 'float',
        ];
    }

    public function getReceiptUrlAttribute(): ?string
    {
        return $this->receipt_path ? '/storage/' . ltrim($this->receipt_path, '/') : null;
    }

    public function messMonth(): BelongsTo
    {
        return $this->belongsTo(MessMonth::class);
    }

    public function buyer(): BelongsTo
    {
        return $this->belongsTo(User::class, 'bought_by');
    }

    public function creator(): BelongsTo
    {
        return $this->belongsTo(User::class, 'created_by');
    }
}
