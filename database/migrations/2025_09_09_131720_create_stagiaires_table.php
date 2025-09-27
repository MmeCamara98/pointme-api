<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::create('stagiaires', function (Blueprint $table) {
    $table->id();
    $table->foreignId('coach_id')->nullable()->constrained('coaches')->cascadeOnDelete();
    $table->string('first_name');
    $table->string('last_name');
    $table->string('email')->nullable();
    $table->string('phone')->nullable();
    $table->string('promotion')->nullable();
    $table->date('start_date')->nullable();
    $table->date('end_date')->nullable();
    $table->string('password')->nullable();
    $table->timestamps();
});

    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('stagiaires');
    }
};
