#pragma once

#include "CoreMinimal.h"
#include "GameFramework/Actor.h"
#include "MHInteractable.h"
#include "MHSafehouseActor.generated.h"

class USphereComponent;

UCLASS(BlueprintType)
class MOUNTHOPE_API AMHSafehouseActor : public AActor, public IMHInteractable
{
    GENERATED_BODY()

public:
    AMHSafehouseActor();

    virtual FText GetInteractionPrompt_Implementation() const override;
    virtual void Interact_Implementation(APawn* InstigatorPawn) override;

protected:
    virtual void BeginPlay() override;

    UPROPERTY(VisibleAnywhere, BlueprintReadOnly, Category = "Mount Hope|Safehouse")
    TObjectPtr<USphereComponent> InteractionSphere;

    UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Mount Hope|Safehouse")
    FString SafehouseName = TEXT("Mount Hope Safehouse");

    UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Mount Hope|Safehouse")
    float InteractionRadius = 250.0f;

    UPROPERTY(EditAnywhere, BlueprintReadOnly, Category = "Mount Hope|Safehouse")
    FVector SpawnOffset = FVector(0.0f, 200.0f, 0.0f);
};
