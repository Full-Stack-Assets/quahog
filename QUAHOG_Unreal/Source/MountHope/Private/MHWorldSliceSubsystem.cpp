#include "MHWorldSliceSubsystem.h"

#include "Dom/JsonObject.h"
#include "Misc/FileHelper.h"
#include "Misc/Paths.h"
#include "Serialization/JsonReader.h"
#include "Serialization/JsonSerializer.h"

namespace
{
FString ResolvePath(const FString& RelativeOrAbsolutePath)
{
    if (FPaths::FileExists(RelativeOrAbsolutePath))
    {
        return RelativeOrAbsolutePath;
    }

    return FPaths::ConvertRelativePathToFull(FPaths::ProjectDir() / RelativeOrAbsolutePath);
}

bool ReadVec2Array(const TArray<TSharedPtr<FJsonValue>>& JsonPoints, TArray<FVector2D>& OutPoints)
{
    OutPoints.Reset();
    OutPoints.Reserve(JsonPoints.Num());

    for (const TSharedPtr<FJsonValue>& PointValue : JsonPoints)
    {
        const TArray<TSharedPtr<FJsonValue>>* Pair = nullptr;
        if (!PointValue.IsValid() || !PointValue->TryGetArray(Pair) || !Pair || Pair->Num() < 2)
        {
            return false;
        }

        OutPoints.Add(FVector2D(
            static_cast<float>((*Pair)[0]->AsNumber()),
            static_cast<float>((*Pair)[1]->AsNumber())));
    }

    return true;
}
}

bool UMHWorldSliceSubsystem::LoadSliceFromJson(const FString& RelativeOrAbsolutePath)
{
    const FString FullPath = ResolvePath(RelativeOrAbsolutePath);
    FString RawJson;
    if (!FFileHelper::LoadFileToString(RawJson, *FullPath))
    {
        UE_LOG(LogTemp, Error, TEXT("MountHope: Unable to load slice JSON: %s"), *FullPath);
        return false;
    }

    TSharedPtr<FJsonObject> RootObject;
    TSharedRef<TJsonReader<>> Reader = TJsonReaderFactory<>::Create(RawJson);
    if (!FJsonSerializer::Deserialize(Reader, RootObject) || !RootObject.IsValid())
    {
        UE_LOG(LogTemp, Error, TEXT("MountHope: Invalid JSON in slice file: %s"), *FullPath);
        return false;
    }

    SliceName = RootObject->GetStringField(TEXT("name"));

    const TSharedPtr<FJsonObject>* OriginObject = nullptr;
    if (RootObject->TryGetObjectField(TEXT("origin"), OriginObject) && OriginObject && OriginObject->IsValid())
    {
        OriginLatLon.X = static_cast<float>((*OriginObject)->GetNumberField(TEXT("lat")));
        OriginLatLon.Y = static_cast<float>((*OriginObject)->GetNumberField(TEXT("lon")));
    }

    Roads.Reset();
    Buildings.Reset();
    Landmarks.Reset();

    const TArray<TSharedPtr<FJsonValue>>* RoadsArray = nullptr;
    if (RootObject->TryGetArrayField(TEXT("roads"), RoadsArray) && RoadsArray)
    {
        Roads.Reserve(RoadsArray->Num());
        for (const TSharedPtr<FJsonValue>& RoadValue : *RoadsArray)
        {
            const TSharedPtr<FJsonObject> RoadObject = RoadValue->AsObject();
            if (!RoadObject.IsValid())
            {
                continue;
            }

            FMHRoadRecord Record;
            Record.Name = RoadObject->GetStringField(TEXT("name"));
            Record.Highway = RoadObject->GetStringField(TEXT("highway"));
            Record.Width = static_cast<float>(RoadObject->GetNumberField(TEXT("width")));

            const TArray<TSharedPtr<FJsonValue>>* PointsArray = nullptr;
            if (RoadObject->TryGetArrayField(TEXT("points"), PointsArray) && PointsArray)
            {
                ReadVec2Array(*PointsArray, Record.Centerline.Points);
            }

            Roads.Add(MoveTemp(Record));
        }
    }

    const TArray<TSharedPtr<FJsonValue>>* BuildingsArray = nullptr;
    if (RootObject->TryGetArrayField(TEXT("buildings"), BuildingsArray) && BuildingsArray)
    {
        Buildings.Reserve(BuildingsArray->Num());
        for (const TSharedPtr<FJsonValue>& BuildingValue : *BuildingsArray)
        {
            const TSharedPtr<FJsonObject> BuildingObject = BuildingValue->AsObject();
            if (!BuildingObject.IsValid())
            {
                continue;
            }

            FMHBuildingRecord Record;
            Record.Name = BuildingObject->GetStringField(TEXT("name"));
            Record.Height = static_cast<float>(BuildingObject->GetNumberField(TEXT("height")));

            const TArray<TSharedPtr<FJsonValue>>* FootprintArray = nullptr;
            if (BuildingObject->TryGetArrayField(TEXT("footprint"), FootprintArray) && FootprintArray)
            {
                ReadVec2Array(*FootprintArray, Record.Footprint.Points);
            }

            Buildings.Add(MoveTemp(Record));
        }
    }

    const TArray<TSharedPtr<FJsonValue>>* LandmarksArray = nullptr;
    if (RootObject->TryGetArrayField(TEXT("landmarks"), LandmarksArray) && LandmarksArray)
    {
        Landmarks.Reserve(LandmarksArray->Num());
        for (const TSharedPtr<FJsonValue>& LandmarkValue : *LandmarksArray)
        {
            const TSharedPtr<FJsonObject> LandmarkObject = LandmarkValue->AsObject();
            if (!LandmarkObject.IsValid())
            {
                continue;
            }

            FMHLandmarkRecord Record;
            Record.Name = LandmarkObject->GetStringField(TEXT("name"));
            Record.bHero = LandmarkObject->GetBoolField(TEXT("hero"));

            const TArray<TSharedPtr<FJsonValue>>* Pos = nullptr;
            if (LandmarkObject->TryGetArrayField(TEXT("pos"), Pos) && Pos && Pos->Num() >= 3)
            {
                Record.Location = FVector(
                    static_cast<float>((*Pos)[0]->AsNumber()),
                    static_cast<float>((*Pos)[1]->AsNumber()),
                    static_cast<float>((*Pos)[2]->AsNumber()));
            }

            Landmarks.Add(MoveTemp(Record));
        }
    }

    UE_LOG(LogTemp, Log, TEXT("MountHope: Loaded slice '%s' (%d roads, %d buildings, %d landmarks)"),
        *SliceName, Roads.Num(), Buildings.Num(), Landmarks.Num());

    return true;
}

bool UMHWorldSliceSubsystem::IsSliceLoaded() const
{
    return !SliceName.IsEmpty() && Roads.Num() > 0;
}
