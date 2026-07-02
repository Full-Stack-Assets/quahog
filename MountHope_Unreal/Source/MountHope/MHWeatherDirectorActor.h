#pragma once

#include "CoreMinimal.h"
#include "GameFramework/Actor.h"
#include "MHGameStateSubsystem.h"
#include "MHWeatherDirectorActor.generated.h"

class ADirectionalLight;
class AExponentialHeightFog;
class UDirectionalLightComponent;
class UExponentialHeightFogComponent;

USTRUCT(BlueprintType)
struct FMHWeatherProfile
{
    GENERATED_BODY()

    UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Mount Hope|Weather")
    float FogDensity = 0.02f;

    UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Mount Hope|Weather")
    float FogHeightFalloff = 0.2f;

    UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Mount Hope|Weather")
    FLinearColor FogColor = FLinearColor(0.72f, 0.78f, 0.85f);

    UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Mount Hope|Weather")
    float SunIntensity = 6.0f;

    UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Mount Hope|Weather")
    FLinearColor SunColor = FLinearColor(1.0f, 0.96f, 0.88f);
};

UCLASS()
class MOUNTHOPE_API AMHWeatherDirectorActor : public AActor
{
    GENERATED_BODY()

public:
    AMHWeatherDirectorActor();

    virtual void BeginPlay() override;
    virtual void Tick(float DeltaSeconds) override;

    UFUNCTION(BlueprintCallable, Category = "Mount Hope|Weather")
    void ApplyWeather(EMHWeatherState WeatherState, bool bInstant = true);

protected:
    UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Mount Hope|Weather")
    FMHWeatherProfile ClearProfile;

    UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Mount Hope|Weather")
    FMHWeatherProfile DenseFogProfile;

    UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Mount Hope|Weather")
    FMHWeatherProfile CoastalRainProfile;

    UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Mount Hope|Weather")
    FMHWeatherProfile NoreasterProfile;

    UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Mount Hope|Weather")
    float BlendSpeed = 0.65f;

private:
    UPROPERTY(Transient)
    TObjectPtr<UDirectionalLightComponent> SunLightComponent;

    UPROPERTY(Transient)
    TObjectPtr<UExponentialHeightFogComponent> FogComponent;

    UPROPERTY(Transient)
    EMHWeatherState ActiveWeather = EMHWeatherState::Clear;

    UPROPERTY(Transient)
    EMHWeatherState TargetWeather = EMHWeatherState::Clear;

    UPROPERTY(Transient)
    FMHWeatherProfile CurrentProfile;

    UPROPERTY(Transient)
    FMHWeatherProfile TargetProfile;

    UFUNCTION()
    void HandleWeatherChanged(EMHWeatherState NewWeather);

    void ResolveSceneComponents();
    void EnsureFogActor();
    const FMHWeatherProfile& GetProfileForState(EMHWeatherState WeatherState) const;
    void TickBlend(float DeltaSeconds);
    void ApplyProfile(const FMHWeatherProfile& Profile);
    FMHWeatherProfile LerpProfiles(const FMHWeatherProfile& From, const FMHWeatherProfile& To, float Alpha) const;
};
