<?php

namespace App\Providers;

use Illuminate\Support\ServiceProvider;

class AppServiceProvider extends ServiceProvider
{
    /**
     * Register any application services.
     */
    public function register(): void
    {
        //
    }

    /**
     * Bootstrap any application services.
     */
    public function boot(): void
    {
        FilamentAsset::register([
        'app.css' => asset('build/assets/app-DUJd_Yy-.css'),
        'app.js' => asset('build/assets/app-Bj43h_rG.js'),
    ]);
    }
}    