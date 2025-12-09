//
//  GameQuestionGenerator.swift
//  lie-detect
//
//  Created by Mikołaj Niżnik on 09/12/2025.
//

import Foundation

/// Generates game questions for different scenarios
struct GameQuestionGenerator {
    
    /// Generate a random question pack
    static func generateQuestionPack(count: Int = 10, categories: [QuestionCategory] = [.general, .personal, .spicy]) -> [GameQuestion] {
        let allQuestions = getAllQuestions(for: categories)
        return Array(allQuestions.shuffled().prefix(count))
    }
    
    /// Get all available questions for given categories
    private static func getAllQuestions(for categories: [QuestionCategory]) -> [GameQuestion] {
        var questions: [GameQuestion] = []
        
        for category in categories {
            questions.append(contentsOf: getQuestions(for: category))
        }
        
        return questions
    }
    
    /// Get questions for a specific category
    private static func getQuestions(for category: QuestionCategory) -> [GameQuestion] {
        switch category {
        case .general:
            return generalQuestions
        case .personal:
            return personalQuestions
        case .spicy:
            return spicyQuestions
        case .relationships:
            return relationshipQuestions
        case .secrets:
            return secretQuestions
        }
    }
    
    // MARK: - Question Banks
    
    private static let generalQuestions: [GameQuestion] = [
        GameQuestion(text: "Czy kiedykolwiek przekroczyłeś/aś prędkość o więcej niż 20 km/h?", category: .general),
        GameQuestion(text: "Czy kiedykolwiek wyszedłeś/aś z restauracji bez płacenia?", category: .general),
        GameQuestion(text: "Czy kiedykolwiek podałeś/aś fałszywe dane w internecie?", category: .general),
        GameQuestion(text: "Czy kiedykolwiek udawałeś/aś chorobę, żeby nie iść do pracy lub szkoły?", category: .general),
        GameQuestion(text: "Czy kiedykolwiek obejrzałeś/aś serial bez swojego partnera, mimo że mieliście oglądać razem?", category: .general),
        GameQuestion(text: "Czy kiedykolwiek zasnąłeś/aś podczas rozmowy wideo?", category: .general),
        GameQuestion(text: "Czy kiedykolwiek skasowałeś/aś wiadomość zaraz po wysłaniu?", category: .general),
        GameQuestion(text: "Czy wierzysz w horoskopy?", category: .general),
        GameQuestion(text: "Czy kiedykolwiek sprawdzałeś/aś telefon drugiej osoby bez jej wiedzy?", category: .general),
        GameQuestion(text: "Czy kiedykolwiek kupiłeś/aś coś tylko dlatego, że było na wyprzedaży?", category: .general),
    ]
    
    private static let personalQuestions: [GameQuestion] = [
        GameQuestion(text: "Czy kiedykolwiek kłamałeś/aś o swoim wieku?", category: .personal),
        GameQuestion(text: "Czy kiedykolwiek płakałeś/aś oglądając film?", category: .personal),
        GameQuestion(text: "Czy masz jakiś sekretny talent?", category: .personal),
        GameQuestion(text: "Czy śpiewasz pod prysznicem?", category: .personal),
        GameQuestion(text: "Czy kiedykolwiek rozmawiałeś/aś sam/a ze sobą?", category: .personal),
        GameQuestion(text: "Czy kiedykolwiek udawałeś/aś, że rozumiesz, o czym ktoś mówi?", category: .personal),
        GameQuestion(text: "Czy żałujesz jakiegoś tatuażu lub przebicia?", category: .personal),
        GameQuestion(text: "Czy czytasz opinie w internecie przed zakupem?", category: .personal),
        GameQuestion(text: "Czy kiedykolwiek wysłałeś/aś wiadomość do złej osoby?", category: .personal),
        GameQuestion(text: "Czy masz jakąś dziwną fobię?", category: .personal),
        GameQuestion(text: "Czy kiedykolwiek udawałeś/aś że jesteś w związku?", category: .personal),
        GameQuestion(text: "Czy wierzysz w duchy?", category: .personal),
    ]
    
    private static let spicyQuestions: [GameQuestion] = [
        GameQuestion(text: "Czy kiedykolwiek pocałowałeś/aś kogoś na pierwszej randce?", category: .spicy),
        GameQuestion(text: "Czy masz crush'a na osobę, która o tym nie wie?", category: .spicy),
        GameQuestion(text: "Czy kiedykolwiek wymyśliłeś/aś wymówkę, żeby nie iść na randkę?", category: .spicy),
        GameQuestion(text: "Czy kiedykolwiek flirtowałeś/aś tylko dla zabawy?", category: .spicy),
        GameQuestion(text: "Czy kiedykolwiek stalkujesz byłych partnerów na social mediach?", category: .spicy),
        GameQuestion(text: "Czy kiedykolwiek randkowałeś/aś z więcej niż jedną osobą na raz?", category: .spicy),
        GameQuestion(text: "Czy miałeś/aś kiedyś przyjaźń z korzyściami?", category: .spicy),
        GameQuestion(text: "Czy kiedykolwiek wróciłeś/aś do byłej osoby mimo że wiedziałeś/aś że to zły pomysł?", category: .spicy),
        GameQuestion(text: "Czy lubiłeś/aś kogoś kto był w związku?", category: .spicy),
        GameQuestion(text: "Czy ghostowałeś/aś kiedyś kogoś?", category: .spicy),
    ]
    
    private static let relationshipQuestions: [GameQuestion] = [
        GameQuestion(text: "Czy kiedykolwiek skłamałeś/aś swojemu partnerowi o tym gdzie byłeś/aś?", category: .relationships),
        GameQuestion(text: "Czy jesteś zazdrosny/a o byłych swoich partnerów?", category: .relationships),
        GameQuestion(text: "Czy wierzysz w miłość od pierwszego wejrzenia?", category: .relationships),
        GameQuestion(text: "Czy kiedykolwiek udawałeś/aś zadowolenie z prezentu który Ci się nie podobał?", category: .relationships),
        GameQuestion(text: "Czy kiedykolwiek przeczytałeś/aś wiadomości partnera?", category: .relationships),
        GameQuestion(text: "Czy kiedykolwiek miałeś/aś sekretny kontakt ze swoim ex?", category: .relationships),
        GameQuestion(text: "Czy powiedziałbyś/abyś białe kłamstwo, żeby nie zranić uczuć partnera?", category: .relationships),
        GameQuestion(text: "Czy kiedykolwiek porównywałeś/aś obecnego partnera z byłym?", category: .relationships),
        GameQuestion(text: "Czy trzymasz pamiątki po byłych związkach?", category: .relationships),
        GameQuestion(text: "Czy kiedykolwiek ktoś powiedział Ci 'kocham Cię' a Ty nie odwzajemniłeś/aś?", category: .relationships),
    ]
    
    private static let secretQuestions: [GameQuestion] = [
        GameQuestion(text: "Czy masz sekrety przed najlepszym przyjacielem?", category: .secrets),
        GameQuestion(text: "Czy kiedykolwiek przeczytałeś/aś czyjś pamiętnik?", category: .secrets),
        GameQuestion(text: "Czy wiesz coś o kimś, czego nikt inny nie wie?", category: .secrets),
        GameQuestion(text: "Czy kiedykolwiek pożyczyłeś/aś coś i nie oddałeś/aś?", category: .secrets),
        GameQuestion(text: "Czy kiedykolwiek ktoś Ci ufał ale zawiodłeś/aś to zaufanie?", category: .secrets),
        GameQuestion(text: "Czy masz konto 'fake' w social mediach?", category: .secrets),
        GameQuestion(text: "Czy ukrywasz jakiś zakup przed rodziną?", category: .secrets),
        GameQuestion(text: "Czy kiedykolwiek użyłeś/aś informacji którą przypadkiem usłyszałeś/aś?", category: .secrets),
        GameQuestion(text: "Czy kiedykolwiek przeczytałeś/aś wiadomość i udawałeś/aś że jej nie widziałeś/aś?", category: .secrets),
        GameQuestion(text: "Czy zrobiłeś/aś kiedyś coś czego bardzo żałujesz?", category: .secrets),
    ]
    
    // MARK: - Preset Packs
    
    static func getQuickGamePack() -> [GameQuestion] {
        generateQuestionPack(count: 5, categories: [.general, .personal])
    }
    
    static func getStandardGamePack() -> [GameQuestion] {
        generateQuestionPack(count: 10, categories: [.general, .personal, .spicy])
    }
    
    static func getExtendedGamePack() -> [GameQuestion] {
        generateQuestionPack(count: 15, categories: [.general, .personal, .spicy, .relationships])
    }
    
    static func getSpicyGamePack() -> [GameQuestion] {
        generateQuestionPack(count: 10, categories: [.spicy, .relationships, .secrets])
    }
}
