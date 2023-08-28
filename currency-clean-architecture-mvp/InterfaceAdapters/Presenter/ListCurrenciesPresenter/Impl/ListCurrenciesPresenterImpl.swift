//
//  ListCurrenciesPresenterImpl.swift
//  currency-conversion-mvp
//
//  Created by Alessandro Comparini on 20/08/23.
//

import Foundation


//  MARK: - DELEGATE
protocol ListCurrenciesPresenterOutput: AnyObject {
    func successListCurrencies()
    func error(title: String, message: String)
}


//  MARK: - CLASS
class ListCurrenciesPresenterImpl: ListCurrenciesPresenter {
    weak var delegate: ListCurrenciesPresenterOutput?
    
    private let listCurrenciesUseCase: ListCurrenciesUseCase
    private let listSymbolsUseCase: ListCurrencySymbolsUseCase
    private let saveFavoriteCurrencyUseCase: SaveFavoriteCurrencyUseCase?
    
    private var currenciesData = [ListCurrencyPresenterDTO]()
    private var favoriteCurrencies = [FavoriteCurrencyDTO]()
    var filteredCurrencies = [ListCurrencyPresenterDTO]()
    
    init(listCurrenciesUseCase: ListCurrenciesUseCase,
         listSymbolsUseCase: ListCurrencySymbolsUseCase,
         saveFavoriteCurrencyUseCase: SaveFavoriteCurrencyUseCase?) {
        self.listCurrenciesUseCase = listCurrenciesUseCase
        self.listSymbolsUseCase = listSymbolsUseCase
        self.saveFavoriteCurrencyUseCase = saveFavoriteCurrencyUseCase
    }
    
    
//  MARK: - PUBLIC FUNCTIONS
    
    func getCurrencies() -> [ListCurrencyPresenterDTO] {
        return currenciesData
    }
    
    func addFavoriteCurrency(_ currency: FavoriteCurrencyDTO) {
        if let index = currenciesData.firstIndex(where: {$0.currencyISO == currency.currencyISO}) {
            currenciesData[index].favorite = true
            self.favoriteCurrencies.append(currency)
        }
        Task {
            do {
                try await saveFavoriteCurrencyUseCase?.save(self.favoriteCurrencies.compactMap({ $0.currencyISO }))
            } catch (let error) {
                delegate?.error(title: "Error", message: "Error: \(error.localizedDescription)" )
            }
        }
    }
    
    func deleteFavoriteCurrency(_ currencyISO: String) {
        if let index = currenciesData.firstIndex(where: { $0.currencyISO == currencyISO }) {
            currenciesData[index].favorite = false
            self.favoriteCurrencies.removeAll(where: {$0.currencyISO == currencyISO} )
        }

    }
    
    func listCurrencies() {
        Task {
            do {
                
                //TODO: - Passar estas 3 chamadas para o DispatchGroup
                //Mark: - Get Currencies
                let currencies: [ListCurrencyUseCaseResponse] = try await listCurrenciesUseCase.listCurrencies()
                
                //Mark: - Get Symbols
                let symbols: [ListCurrencySymbolsUseCaseResponse] = try await listSymbolsUseCase.listSymbols()
                
                //Mark: - Get Favorites
                let favorites: Bool = false
                
                //TODO: - UNIR AS 3 CHAMADAS E RETORNAR
                self.currenciesData = currencies.map { let currency = $0
                    var dto = ListCurrencyPresenterDTO()
                    dto.currencyISO = $0.currencyISO
                    dto.name = currency.name
                    dto.favorite = favorites
                    if let symbol = symbols.first(where: { $0.currencyISO == currency.currencyISO } ) {
                        dto.symbol = symbol.symbol
                    }
                    return dto
                }
                
                self.filteredCurrencies = self.currenciesData
                
                DispatchQueue.main.async { [weak self] in
                    guard let self else {return}
                    delegate?.successListCurrencies()
                }
                
            } catch (let error) {
                DispatchQueue.main.async { [weak self] in
                    guard let self else {return}
                    delegate?.error(title: "Error", message: "Error: \(error.localizedDescription)" )
                }
            }
            
        }
    }
    
    
}


//  MARK: - EXTENSION - ListCurrenciesPresenterDataSource

extension ListCurrenciesPresenterImpl: ListCurrenciesPresenterDataSource {
    func numberOfCurrencies() -> Int { currenciesData.count  }
    
    func setFilteredCurrencies(_ currencies: [ListCurrencyPresenterDTO] ) {
        self.filteredCurrencies = currencies
    }
    
    func symbol(index: Int) -> String { filteredCurrencies[index].symbol ?? "" }
    
    func currencyISO(index: Int) -> String { filteredCurrencies[index].currencyISO ?? "" }
    
    func name(index: Int) -> String { NSLocalizedString(filteredCurrencies[index].name ?? "", comment: "") }
    
    func favorite(index: Int) -> Bool { filteredCurrencies[index].favorite ?? false }
    
}


