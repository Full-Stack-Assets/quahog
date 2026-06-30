#include "MHWeatherDirectorActor.h"

#include "Components/DirectionalLightComponent.h"
#include "Components/ExponentialHeightFogComponent.h"
#include "Engine/DirectionalLight.h"
#include "Engine/ExponentialHeightFog.h"
#include "Engine/World.h"
#include "GameFramework/Actor.h"
#include "Kismet/GameplayStatics.h"

AMHWeatherDirectorActor::AMHWeatherDirectorActor()
{
    PrimaryActorTick.bCanEverTick = true;

    ClearProfile.FogDensity = 0.015f;
    ClearProfile.SunIntensity = 7.5f;

    DenseFogProfile.FogDensity = 0.08f;
    DenseFogProfile.FogColor = FLinearColor(0.62f, 0.66f, 0.7f);
    DenseFogProfile.SunIntensity = 3.5f;

    CoastalRainProfile.FogDensity = 0.05f;
    CoastalRainProfile.FogColor = FLinearColor(0.45f, 0.5f, 0.56f);
    CoastalRainProfile.SunIntensity = 2.2f;
    CoastalRainProfile.SunColor = FLinearColor(0.75f, 0.8f, 0.88f);

    NoreasterProfile.FogDensity = 0.12f;
    NoreasterProfile.FogColor = FLinearColor(0.35f, 0.38f, 0.42f);
    NoreasterProfile.SunIntensity = 1.2f;
    NoreasterProfile.SunColor = FLinearColor(0.6f, 0.65f, 0.72f);
}

void AMHWeatherDirectorActor::BeginPlay()
{
    Super::BeginPlay();

    ResolveSceneComponents();
    EnsureFogActor();

    if (UGameInstance* GameInstance = GetGameInstance())
    {
        if (UMHGameStateSubsystem* GameState = GameInstance->GetSubsystem<UMHGameStateSubsystem>())
        {
            GameState->OnWeatherChanged.AddDynamic(this, &AMHWeatherDirectorActor::HandleWeatherChanged);
            ApplyWeather(GameState->Weather, true);
        }
    }
}

void AMHWeatherDirectorActor::Tick(float DeltaSeconds)
{
    Super::Tick(DeltaSeconds);
    TickBlend(DeltaSeconds);
}

void AMHWeatherDirectorActor::ApplyWeather(EMHWeatherState WeatherState, bool bInstant)
{
    TargetWeather = WeatherState;
    TargetProfile = GetProfileForState(WeatherState);

    if (bInstant)
    {
        ActiveWeather = TargetWeather;
        CurrentProfile = TargetProfile;
        ApplyProfile(CurrentProfile);
    }
}

void AMHWeatherDirectorActor::HandleWeatherChanged(EMHWeatherState NewWeather)
{
    ApplyWeather(NewWeather, false);
}

void AMHWeatherDirectorActor::ResolveSceneComponents()
{
    if (!GetWorld())
    {
        return;
    }

    if (!SunLightComponent)
    {
        TArray<AActor*> SunActors;
        UGameplayStatics::GetAllActorsOfClass(GetWorld(), ADirectionalLight::StaticClass(), SunActors);
        if (SunActors.Num() > 0)
        {
            if (ADirectionalLight* Sun = Cast<ADirectionalLight>(SunActors[0]))
            {
                SunLightComponent = Sun->FindComponentByClass<UDirectionalLightComponent>();
            }
        }
    }

    if (!FogComponent)
    {
        TArray<AActor*> FogActors;
        UGameplayStatics::GetAllActorsOfClass(GetWorld(), AExponentialHeightFog::StaticClass(), FogActors);
        if (FogActors.Num() > 0)
        {
            if (AExponentialHeightFog* Fog = Cast<AExponentialHeightFog>(FogActors[0]))
            {
                FogComponent = Fog->FindComponentByClass<UExponentialHeightFogComponent>();
            }
        }
    }
}

void AMHWeatherDirectorActor::EnsureFogActor()
{
    if (FogComponent || !GetWorld())
    {
        return;
    }

    FActorSpawnParameters SpawnParams;
    SpawnParams.Name = TEXT("MH_AutoFog");
    AExponentialHeightFog* FogActor = GetWorld()->SpawnActor<AExponentialHeightFog>(
        AExponentialHeightFog::StaticClass(),
        FVector::ZeroVector,
        FRotator::ZeroRotator,
        SpawnParams);

    if (FogActor)
    {
        FogComponent = FogActor->FindComponentByClass<UExponentialHeightFogComponent>();
    }
}

const FMHWeatherProfile& AMHWeatherDirectorActor::GetProfileForState(EMHWeatherState WeatherState) const
{
    switch (WeatherState)
    {
    case EMHWeatherState::DenseFog:
        return DenseFogProfile;
    case EMHWeatherState::CoastalRain:
        return CoastalRainProfile;
    case EMHWeatherState::Noreaster:
        return NoreasterProfile;
    default:
        return ClearProfile;
    }
}

void AMHWeatherDirectorActor::TickBlend(float DeltaSeconds)
{
    if (FMath::IsNearlyEqual(CurrentProfile.FogDensity, TargetProfile.FogDensity, 0.0005f)
        && FMath::IsNearlyEqual(CurrentProfile.SunIntensity, TargetProfile.SunIntensity, 0.01f))
    {
        ActiveWeather = TargetWeather;
        return;
    }

    const float Alpha = FMath::Clamp(DeltaSeconds * BlendSpeed, 0.0f, 1.0f);
    CurrentProfile = LerpProfiles(CurrentProfile, TargetProfile, Alpha);
    ApplyProfile(CurrentProfile);
}

void AMHWeatherDirectorActor::ApplyProfile(const FMHWeatherProfile& Profile)
{
    if (FogComponent)
    {
        FogComponent->SetFogDensity(Profile.FogDensity);
        FogComponent->SetFogHeightFalloff(Profile.FogHeightFalloff);
        FogComponent->SetFogInscatteringColor(Profile.FogColor);
    }

    if (SunLightComponent)
    {
        SunLightComponent->SetIntensity(Profile.SunIntensity);
        SunLightComponent->SetLightColor(Profile.SunColor);
    }
}

FMHWeatherProfile AMHWeatherDirectorActor::LerpProfiles(
    const FMHWeatherProfile& From,
    const FMHWeatherProfile& To,
    float Alpha) const
{
    FMHWeatherProfile Result;
    Result.FogDensity = FMath::Lerp(From.FogDensity, To.FogDensity, Alpha);
    Result.FogHeightFalloff = FMath::Lerp(From.FogHeightFalloff, To.FogHeightFalloff, Alpha);
    Result.FogColor = FMath::Lerp(From.FogColor, To.FogColor, Alpha);
    Result.SunIntensity = FMath::Lerp(From.SunIntensity, To.SunIntensity, Alpha);
    Result.SunColor = FMath::Lerp(From.SunColor, To.SunColor, Alpha);
    return Result;
}
