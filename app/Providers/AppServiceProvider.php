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
        // IMPORTANT pour Filament sur Render
        if (config('app.env') === 'production') {
            URL::forceScheme('https');
            $this->app['url']->forceRootUrl(config('app.url'));
        }
    }
}    