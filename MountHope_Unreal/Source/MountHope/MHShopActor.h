#pragma once

#include "CoreMinimal.h"
#include "GameFramework/Actor.h"
#include "GameplayTagContainer.h"
#include "MHInteractable.h"
#include "MHShopActor.generated.h"

class USphereComponent;

UENUM(BlueprintType)
enum class EMHShopType : uint8
{
    Garage = 0,
    GeneralStore = 1
};

UCLASS(BlueprintType)
class MOUNTHOPE_API AMHShopActor : public AActor, public IMHInteractable
{
    GENERATED_BODY()

public:
    AMHShopActor();

    virtual FText GetInteractionPrompt_Implementation() const override;
    virtual void Interact_Implementation(APawn* InstigatorPawn) override;

protected:
    virtual void BeginPlay() override;

    UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category = "Mount Hope|Shop")
    TObjectPtr<USphereComponent> InteractionSphere;

    UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Mount Hope|Shop")
    FString ShopName = TEXT("The Anvil Garage");

    UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Mount Hope|Shop")
    EMHShopType ShopType = EMHShopType::Garage;

    UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Mount Hope|Shop")
    FString LinkedBusinessId;

    UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Mount Hope|Shop")
    int32 BaseRepairCost = 150;

    UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Mount Hope|Shop")
    float VehicleServiceRange = 500.0f;

    UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Mount Hope|Shop")
    float InteractionRadius = 250.0f;

    UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Mount Hope|Shop")
    FGameplayTag ReputationFactionTag;

    UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Mount Hope|Shop")
    int32 ReputationDiscountThreshold = 25;

    UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Mount Hope|Shop")
    float ReputationDiscountPct = 0.25f;

private:
    void HandleGarageInteraction(APawn* InstigatorPawn);
    void HandleGeneralStoreInteraction(APawn* InstigatorPawn);
    int32 GetEffectiveRepairCost() const;
    class AMHVehiclePawn* FindNearestDamagedVehicle(const APawn* InstigatorPawn) const;
};
