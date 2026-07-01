#pragma once

#include "CoreMinimal.h"
#include "GameFramework/Actor.h"
#include "MHInteractable.h"
#include "MHWeaponPickupActor.generated.h"

class USphereComponent;
class UStaticMeshComponent;
class USoundBase;

UCLASS(BlueprintType)
class MOUNTHOPE_API AMHWeaponPickupActor : public AActor, public IMHInteractable
{
    GENERATED_BODY()

public:
    AMHWeaponPickupActor();

    virtual FText GetInteractionPrompt_Implementation() const override;
    virtual void Interact_Implementation(APawn* InstigatorPawn) override;

protected:
    virtual void BeginPlay() override;

    UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category = "Mount Hope|Weapon")
    TObjectPtr<USphereComponent> InteractionSphere;

    UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category = "Mount Hope|Weapon")
    TObjectPtr<UStaticMeshComponent> DisplayMesh;

    UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Mount Hope|Weapon")
    int32 AmmoAmount = 12;

    UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Mount Hope|Weapon")
    float InteractionRadius = 200.0f;

    UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Mount Hope|Audio")
    TObjectPtr<USoundBase> PickupSound;
};
