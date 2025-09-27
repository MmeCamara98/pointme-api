<?php

namespace App\Http\Controllers;

use Illuminate\Http\Request;
use App\Models\Stagiaire;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Validator;
use Tymon\JWTAuth\Facades\JWTAuth;

class AuthStagiaireController extends Controller
{
    public function register(Request $request)
    {
        $validator = Validator::make($request->all(), [
            'first_name' => 'required|string|max:255',
            'last_name' => 'required|string|max:255',
            'email' => 'required|string|email|max:255|unique:stagiaires',
            'phone' => 'required|string|max:20',
            'promotion' => 'nullable|string|max:255',
            'start_date' => 'nullable|date',
            'end_date' => 'nullable|date',
            'password' => 'required|string|min:6|confirmed',
        ]);

        if ($validator->fails()) {
            return response()->json($validator->errors(), 422);
        }

        $stagiaire = Stagiaire::create([
            'first_name' => $request->first_name,
            'last_name' => $request->last_name,
            'email' => $request->email,
            'phone' => $request->phone,
            'promotion' => $request->promotion,
            'start_date' => $request->start_date,
            'end_date' => $request->end_date,
            'password' => $request->password, // Le mutator s'occupera du hashage
        ]);

        $token = auth('stagiaire')->login($stagiaire);

        return response()->json([
            'message' => 'Stagiaire inscrit avec succès',
            'user' => $stagiaire,
            'token' => $token
        ], 201);
    }

    public function login(Request $request)
    {
        $credentials = $request->only('email', 'password');
        if (! $token = auth('stagiaire')->attempt($credentials)) {
            return response()->json(['error' => 'Email ou mot de passe incorrect'], 401);
        }
        return response()->json([
            'message' => 'Connexion réussie',
            'user' => auth('stagiaire')->user(),
            'token' => $token
        ]);
    }

    public function profile()
    {
        return response()->json(auth('stagiaire')->user());
    }

    public function logout()
    {
        auth('stagiaire')->logout();
        return response()->json(['message' => 'Déconnexion réussie']);
    }
}
