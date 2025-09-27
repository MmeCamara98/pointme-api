<?php
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Route;
use App\Http\Controllers\AuthCoachController;

// Authentification coach
Route::post('/coach/login', [AuthCoachController::class, 'login']);
Route::post('/coach/register', [AuthCoachController::class, 'register']);

// Routes protégées coach
Route::group(['middleware' => ['auth:coach']], function () {
    Route::get('/coach/me', [AuthCoachController::class, 'me']);
    Route::post('/coach/logout', [AuthCoachController::class, 'logout']);
    Route::get('/coach/profile', [AuthCoachController::class, 'profile']);
});

// Stagiaire Auth
use App\Http\Controllers\AuthStagiaireController;
Route::post('/stagiaire/register', [AuthStagiaireController::class, 'register']);
Route::post('/stagiaire/login', [AuthStagiaireController::class, 'login']);

// Routes protégées stagiaire
Route::group(['middleware' => ['auth:stagiaire']], function () {
    Route::get('/stagiaire/profile', [AuthStagiaireController::class, 'profile']);
    Route::post('/stagiaire/logout', [AuthStagiaireController::class, 'logout']);
});