<?php

namespace App\Http\Controllers;
use App\Models\coach;
use Illuminate\Support\Facades\Hash;
use Tymon\JWTAuth\Facades\JWTAuth;

use Illuminate\Http\Request;

class AuthCoachController extends Controller
{
    //
 public function login(Request $request)
    {
        $credentials = $request->only('email', 'password');

        if (! $token = auth('coach')->attempt($credentials)) {
            return response()->json(['error' => 'Email ou mot de passe invalide'], 401);
        }

        return response()->json([
            'message' => 'Connexion réussie',
            'token' => $token,
            'user'  => auth('coach')->user()
        ]);
    }

    public function logout()
    {
        auth('coach')->logout();
        return response()->json(['message' => 'Déconnexion réussie']);
    }

    public function me()
    {
        return response()->json(auth('coach')->user());
    }
}
