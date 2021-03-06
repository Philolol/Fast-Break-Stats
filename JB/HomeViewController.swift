//
//  HomeViewController.swift
//
//  Created by Raymond Li on 8/12/18.
//  Copyright © 2018 Raymond Li. All rights reserved.
//

import UIKit

class HomeViewController: UIViewController, NSURLConnectionDelegate {
    
    @IBOutlet weak var headerView: PlayerOverviewHead!
    @IBOutlet weak var personalView: PlayerPersonal!
    @IBOutlet weak var rankingsView: PlayerRankings!
    
    var playerImage: UIImage?
    var playerId: Int = -1
    var firstName: String = ""
    var lastName: String = ""
    var displayName: String = ""
    var player: Player = Player()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if playerImage == nil {
            playerImage = getPlayerImage()
        }
        
        getPlayer()
        sleep(1)
        
        getNextGameJSON()
        getStatRankings(category: "EFF")
        getStatRankings(category: "MIN")
        getStatRankings(category: "PTS")
        getStatRankings(category: "REB")
        getStatRankings(category: "AST")
        getStatRankings(category: "STL")
        getStatRankings(category: "BLK")
        getStatRankings(category: "TOV")
    }
    
    
    func getPlayer() {
        let urlString = "https://stats.nba.com/stats/commonplayerinfo/?PlayerId=" + String(playerId)
        let url = URL(string: urlString)

        URLSession.shared.dataTask(with: url!, completionHandler: {(data, response, error) in
            if data != nil {
                do {
                    let json = try JSONSerialization.jsonObject(with: data!, options: JSONSerialization.ReadingOptions.allowFragments) as! [String: Any]
                    let resultSetsTemp: NSArray = json["resultSets"] as! NSArray
                    let resultSets = resultSetsTemp[0] as! [String: Any]
                    let rowSet: NSArray = resultSets["rowSet"] as! NSArray

                    self.turnRowSetIntoPlayer(rowSet)
                } catch {
                    print("Could not serialize")
                }
            }
        }).resume()
    }
    
    func getNextGameJSON() {
        guard let team = getTeamName(team: player.currentTeam) else {
            return
        }
        
        let urlString = "http://data.nba.net/data/10s/prod/v1/2018/teams/" + team + "/schedule.json"
        let url = URL(string: urlString)
        
        URLSession.shared.dataTask(with: url!, completionHandler: {(data, response, error) in
            if data != nil {
                do {
                    let json = try JSONSerialization.jsonObject(with: data!, options: JSONSerialization.ReadingOptions.allowFragments) as! [String: Any]
                    let league = json["league"] as! [String: Any]
                    let games: NSArray = league["standard"] as! NSArray

                    if games.count == 0 {
                        return
                    } else {
                        let nextGame = games[0] as! [String: Any]
                        let startTime = nextGame["startTimeUTC"] as! String
                        let startDate = nextGame["startDateEastern"] as! String
                        let isHomeTeam = nextGame["isHomeTeam"] as! Bool
                        
                        var nextGameOpponent = ""
                        var homeOAway = ""
                        
                        if isHomeTeam {
                            let vTeam = nextGame["vTeam"] as! [String: String]
                            let oppo = vTeam["teamId"]
                            nextGameOpponent = self.getTeamFromId(teamId: oppo!)
                            homeOAway = "vs"
                        } else {
                            let hTeam = nextGame["hTeam"] as! [String: String]
                            let oppo = hTeam["teamId"]
                            nextGameOpponent = self.getTeamFromId(teamId: oppo!)
                            homeOAway = "@"
                        }
                        
                        let nextGameDate = self.formatDate(date: startDate)
                        let nextGameTime = self.formatTime(time: startTime)
                        let nextGameDetails = homeOAway + " " + nextGameOpponent + " - " + nextGameTime
                        
                        let birthDetails = self.player.birthDate + " (Age: " + self.player.age + ")"
                        let draftDetails = self.player.draftYear + ": Rd " + self.player.draftRound + ", Pick " + self.player.draftNumber
                        let heightWeightDetails = self.player.height + ", " + self.player.weight + " lbs"
                        
                        DispatchQueue.main.async(execute: {
                            self.headerView.headshot.image = self.player.headshot
                            self.headerView.number.text = "#" + self.player.jerseyNumber
                            self.headerView.position.text = self.player.position
                            self.headerView.name.text = self.displayName
                            self.headerView.team.text = self.player.currentTeam
                            self.headerView.gameDate.text = "Next Game: " + nextGameDate
                            self.headerView.gameDetail.text = nextGameDetails

                            self.personalView.birthDateLabel.text = birthDetails
                            self.personalView.draftLabel.text = draftDetails
                            self.personalView.schoolLabel.text = self.player.school
                            self.personalView.experienceLabel.text = self.player.yearsExperience
                            self.personalView.heightWeightLabel.text = heightWeightDetails
                        })
                    }
                } catch {
                    print("Could not serialize")
                }
            }
        }).resume()
    }
    
    func getStatRankings(category: String) {
        let urlString = "https://stats.nba.com/stats/leagueleaders/?LeagueID=00&Season=2017-18&PerMode=PerGame&SeasonType=Regular+Season&Scope=RS&StatCategory=" + category
        let url = URL(string: urlString)
        
        URLSession.shared.dataTask(with: url!, completionHandler: {(data, response, error) in
            if data != nil {
                do {
                    let json = try JSONSerialization.jsonObject(with: data!, options: JSONSerialization.ReadingOptions.allowFragments) as! [String: Any]
                    let resultSets = json["resultSet"] as! [String: Any]
                    let rowSet: NSArray = resultSets["rowSet"] as! NSArray
                    
                    let rankingArr = self.findRanking(rowSet, category: category)
                    let rank = rankingArr[0]
                    let amount = rankingArr[1]
                    
                    switch category {
                    case "EFF":
                        DispatchQueue.main.async(execute: {
                            self.rankingsView.stat1.statType.text = category
                            self.rankingsView.stat1.statAmount.text = amount
                            self.rankingsView.stat1.rank.text = rank
                        })
                    case "MIN":
                        DispatchQueue.main.async(execute: {
                            self.rankingsView.stat2.statType.text = category
                            self.rankingsView.stat2.statAmount.text = amount
                            self.rankingsView.stat2.rank.text = rank
                        })
                    case "PTS":
                        DispatchQueue.main.async(execute: {
                            self.rankingsView.stat3.statType.text = category
                            self.rankingsView.stat3.statAmount.text = amount
                            self.rankingsView.stat3.rank.text = rank
                        })
                    case "REB":
                        DispatchQueue.main.async(execute: {
                            self.rankingsView.stat4.statType.text = category
                            self.rankingsView.stat4.statAmount.text = amount
                            self.rankingsView.stat4.rank.text = rank
                        })
                    case "AST":
                        DispatchQueue.main.async(execute: {
                            self.rankingsView.stat5.statType.text = category
                            self.rankingsView.stat5.statAmount.text = amount
                            self.rankingsView.stat5.rank.text = rank
                        })
                    case "STL":
                        DispatchQueue.main.async(execute: {
                            self.rankingsView.stat6.statType.text = category
                            self.rankingsView.stat6.statAmount.text = amount
                            self.rankingsView.stat6.rank.text = rank
                        })
                    case "BLK":
                        DispatchQueue.main.async(execute: {
                            self.rankingsView.stat7.statType.text = category
                            self.rankingsView.stat7.statAmount.text = amount
                            self.rankingsView.stat7.rank.text = rank
                        })
                    case "TOV":
                        DispatchQueue.main.async(execute: {
                            self.rankingsView.stat8.statType.text = category
                            self.rankingsView.stat8.statAmount.text = amount
                            self.rankingsView.stat8.rank.text = rank
                        })
                    default:
                        print("No stat category")
                    }
                } catch {
                    print("Could not serialize")
                }
            }
        }).resume()
    }
    
    func findRanking(_ rowSet: NSArray, category: String) -> [String] {
        var i = 0
        
        while i < rowSet.count {
            let curPlayer: NSArray = rowSet[i] as! NSArray
            let curId = curPlayer[0] as! Int
            
            if curId == playerId {
                switch category {
                case "EFF":
                    let amountFloat = curPlayer[23] as! Double
                    let roundedAmount = Double(round(100 * amountFloat) / 100)
                    let amount = String(roundedAmount)
                    return ["#" + String(i), amount]
                case "MIN":
                    let amountFloat = curPlayer[5] as! Double
                    let roundedAmount = Double(round(100 * amountFloat) / 100)
                    let amount = String(roundedAmount)
                    return ["#" + String(i), amount]
                case "PTS":
                    let amountFloat = curPlayer[22] as! Double
                    let roundedAmount = Double(round(100 * amountFloat) / 100)
                    let amount = String(roundedAmount)
                    return ["#" + String(i), amount]
                case "REB":
                    let amountFloat = curPlayer[17] as! Double
                    let roundedAmount = Double(round(100 * amountFloat) / 100)
                    let amount = String(roundedAmount)
                    return ["#" + String(i), amount]
                case "AST":
                    let amountFloat = curPlayer[18] as! Double
                    let roundedAmount = Double(round(100 * amountFloat) / 100)
                    let amount = String(roundedAmount)
                    return ["#" + String(i), amount]
                case "STL":
                    let amountFloat = curPlayer[19] as! Double
                    let roundedAmount = Double(round(100 * amountFloat) / 100)
                    let amount = String(roundedAmount)
                    return ["#" + String(i), amount]
                case "BLK":
                    let amountFloat = curPlayer[20] as! Double
                    let roundedAmount = Double(round(100 * amountFloat) / 100)
                    let amount = String(roundedAmount)
                    return ["#" + String(i), amount]
                case "TOV":
                    let amountFloat = curPlayer[21] as! Double
                    let roundedAmount = Double(round(100 * amountFloat) / 100)
                    let amount = String(roundedAmount)
                    return ["#" + String(i), amount]
                default:
                    return ["No Rank", "No Rank"]
                }
            }
            
            i = i + 1
        }
        
        return ["No Rank", "No Rank"]
    }
    
    func formatDate(date: String) -> String {
        let monthStartIndex = date.index(date.startIndex, offsetBy: 4)
        let dayStartIndex = date.index(date.startIndex, offsetBy: 6)

        let monthRange = monthStartIndex..<dayStartIndex
        
        let month = date[monthRange]
        let day = date.suffix(from: dayStartIndex)
        
        return month + "/" + day
    }
    
    func formatTime(time: String) -> String {
        let hourStartIndex = time.index(time.startIndex, offsetBy: 11)
        let hourEndIndex = time.index(time.startIndex, offsetBy: 13)
        
        let minuteStartIndex = time.index(time.startIndex, offsetBy: 14)
        let minuteEndIndex = time.index(time.startIndex, offsetBy: 16)
        
        let hourRange = hourStartIndex..<hourEndIndex
        let minuteRange = minuteStartIndex..<minuteEndIndex
        
        let utcHour = time[hourRange]
        let minuteString = time[minuteRange]
        
        guard let intHour = Int(utcHour) else {
            return "00:00"
        }
        
        var hourString = "00"
        var timeHalf = "PM"
        
        if intHour <= 6 {
            hourString = String(5 + intHour)
            timeHalf = "PM"
        } else if 7 <= intHour && intHour <= 18 {
            hourString = String(intHour - 7)
            timeHalf = "AM"
        } else if intHour == 19 {
            hourString = String(12)
            timeHalf = "PM"
        } else if 20 <= intHour && intHour <= 23 {
            hourString = String(intHour - 19)
            timeHalf = "PM"
        }
        
        return hourString + ":" + minuteString + " " + timeHalf + " PST"
    }
    
    func turnRowSetIntoPlayer(_ rowSet: NSArray) {
        let currentPlayer: NSArray = rowSet[0] as! NSArray
        let firstName = currentPlayer[1] as! String
        let lastName = currentPlayer[2] as! String
        
        let heightString = currentPlayer[10] as! String
        let height = convertHeight(height: heightString)
        let weight = currentPlayer[11] as! String
        
        let positionLong = currentPlayer[14] as! String
        let position = convertPosition(position: positionLong)
        let currentTeam = currentPlayer[18] as! String
        let yearsExperience = String(describing: currentPlayer[12])
        let birthDateString = currentPlayer[6] as! String
        let stringArr = convertBirthDate(birthDate: birthDateString)
        let birthDate = stringArr[0]
        let age = stringArr[1]
        let jerseyNumber = currentPlayer[13] as! String
        var school = currentPlayer[7] as? String
        if school == nil {
            school = "NA"
        } else {
            school = currentPlayer[7] as? String
        }
        let draftYear = currentPlayer[26] as! String
        let draftRound = currentPlayer[27] as! String
        let draftNumber = currentPlayer[28] as! String
        
        var pImage: UIImage
        if let _image = playerImage {
            pImage = _image
        } else {
            pImage = UIImage(named: "NoHeadshot")!
        }
        
        player = Player(headshot: pImage, firstName: firstName, lastName: lastName, height: height, weight: weight, position: position, currentTeam: currentTeam, yearsExperience: yearsExperience, birthDate: birthDate, age: age, jerseyNumber: jerseyNumber, school: school!, draftYear: draftYear, draftRound: draftRound, draftNumber: draftNumber)
        
    }
    
    func getPlayerImage() -> UIImage {
        let urlImage = "https://nba-players.herokuapp.com/players/" + lastName + "/" + firstName
        let url = URL(string: urlImage)
        
        let data = try? Data(contentsOf: url!)
        
        if data == nil {
            return UIImage(named: "NoHeadshot")!
        }
        
        let image = UIImage(data: data!)
        
        if let _image = image {
            return _image
        }
        
        return UIImage(named: "NoHeadshot")!
    }
    
    func formatGameDate(input: String) -> String {
        let index1 = input.index(input.startIndex, offsetBy: 4)
        let year: String = input.substring(to: index1)
        
        let index2 = input.index(input.startIndex, offsetBy: 5)
        let index3 = input.index(input.startIndex, offsetBy: 7)
        let range1 = index2..<index3
        let month: String = input.substring(with: range1)
        
        let index4 = input.index(input.startIndex, offsetBy: 8)
        let index5 = input.index(input.startIndex, offsetBy: 10)
        let range2 = index4..<index5
        let date: String = input.substring(with: range2)
        return month + "/" + date + "/" + year
    }
    
    func formatGameTime(input: String) -> String {
        let index1 = input.index(input.startIndex, offsetBy: 14)
        let index2 = input.index(input.startIndex, offsetBy: 16)
        let range1 = index1..<index2
        let minute = input.substring(with: range1)
        
        let index3 = input.index(input.startIndex, offsetBy: 11)
        let index4 = input.index(input.startIndex, offsetBy: 13)
        let range2 = index3..<index4
        let hour1: String = input.substring(with: range2)
        var intHour: Int = Int(hour1)!
        var ampm: String = "AM"
        
        //Convert to PST
        intHour = intHour - 3
        
        if (intHour >= 12) {
            ampm = "PM"
        }
        if (intHour >= 13) {
            intHour = intHour - 12
        }
        let hour: String = String(describing: intHour)
        
        return hour + ":" + minute + " "  + ampm + " PST"
    }
    
    func convertHeight(height: String) -> String {
        let heightArr = height.components(separatedBy: "-")
        if heightArr.count < 2 {
            return ""
        }
        
        return heightArr[0] + "'" + heightArr[1] + "''"
    }
    
    func convertPosition(position: String) -> String {
        if position == "Guard" {
            return "G"
        } else if position == "Forward" {
            return "F"
        } else if position == "Center" {
            return "C"
        } else if position == "Guard-Forward" || position == "Forward-Guard" {
            return "G/F"
        } else if position == "Forward-Center" || position == "Center-Forward" {
            return "F/C"
        }
        
        return "NA"
    }
    
    func convertBirthDate(birthDate: String) -> [String] {
        let yearEndIndex = birthDate.index(birthDate.startIndex, offsetBy: 4)
        
        let monthStartIndex = birthDate.index(birthDate.startIndex, offsetBy: 5)
        let monthEndIndex = birthDate.index(birthDate.startIndex, offsetBy: 7)
        
        let dayStartIndex = birthDate.index(birthDate.startIndex, offsetBy: 8)
        let dayEndIndex = birthDate.index(birthDate.startIndex, offsetBy: 10)
        
        let yearRange = birthDate.startIndex..<yearEndIndex
        let monthRange = monthStartIndex..<monthEndIndex
        let dayRange = dayStartIndex..<dayEndIndex
        
        let yearString = birthDate[yearRange]
        let monthStringNumber = birthDate[monthRange]
        let monthString = convertMonth(month: monthStringNumber)
        let dayString = birthDate[dayRange]
        
        let age = findAge(dayString: dayString, monthString: monthStringNumber, yearString: yearString)
        
        
        return [monthString + " " + dayString + ", " + yearString, age]
    }
    
    func findAge(dayString: String, monthString: String, yearString: String) -> String {
        guard let day = Int(dayString), let month = Int(monthString), let year = Int(yearString) else {
            return ""
        }
        
        let currentDate = Date()
        let calendar = Calendar.current
        
        let curYear = calendar.component(.year, from: currentDate)
        let curMonth = calendar.component(.month, from: currentDate)
        let curDay = calendar.component(.day, from: currentDate)
        
        if curMonth == month {
            if curDay >= day {
                return String(curYear - year)
            } else {
                return String(curYear - year - 1)
            }
        } else if curMonth < month {
            return String(curYear - year - 1)
        }
        
        return String(curYear - year)
    }
    
    func convertMonth(month: String) -> String {
        switch month {
        case "01":
            return "Jan"
        case "02":
            return "Feb"
        case "03":
            return "Mar"
        case "04":
            return "Apr"
        case "05":
            return "May"
        case "06":
            return "June"
        case "07":
            return "July"
        case "08":
            return "Aug"
        case "09":
            return "Sep"
        case "10":
            return "Oct"
        case "11":
            return "Nov"
        case "12":
            return "Dec"
        default:
            return ""
        }
    }
    
    
    func getTeamName(team: String) -> String? {
        switch team {
        case "ATL":
            return "hawks"
        case "BKN":
            return "nets"
        case "BOS":
            return "celtics"
        case "CHA":
            return "hornets"
        case "CHI":
            return "bulls"
        case "CLE":
            return "cavaliers"
        case "DAL":
            return "mavericks"
        case "DEN":
            return "nuggets"
        case "DET":
            return "pistons"
        case "GSW":
            return "warriors"
        case "HOU":
            return "rockets"
        case "IND":
            return "pacers"
        case "LAC":
            return "clippers"
        case "LAL":
            return "lakers"
        case "MEM":
            return "grizzlies"
        case "MIA":
            return "heat"
        case "MIL":
            return "bucks"
        case "MIN":
            return "timberwolves"
        case "NOP":
            return "pelicans"
        case "NYK":
            return "knicks"
        case "OKC":
            return "thunder"
        case "ORL":
            return "magic"
        case "PHI":
            return "sixers"
        case "PHX":
            return "suns"
        case "POR":
            return "blazers"
        case "SAC":
            return "kings"
        case "SAS":
            return "spurs"
        case "TOR":
            return "raptors"
        case "UTA":
            return "jazz"
        case "WAS":
            return "wizards"
        default:
            return nil
        }
    }
    
    func getTeamFromId(teamId: String) -> String {
        switch teamId {
        case "1610612737":
            return "ATL"
        case "1610612751":
            return "BKN"
        case "1610612738":
            return "BOS"
        case "1610612766":
            return "CHA"
        case "1610612741":
            return "CHI"
        case "1610612739":
            return "CLE"
        case "1610612742":
            return "DAL"
        case "1610612743":
            return "DEN"
        case "1610612765":
            return "DET"
        case "1610612744":
            return "GSW"
        case "1610612745":
            return "HOU"
        case "1610612754":
            return "IND"
        case "1610612746":
            return "LAC"
        case "1610612747":
            return "LAL"
        case "1610612763":
            return "MEM"
        case "1610612748":
            return "MIA"
        case "1610612749":
            return "MIL"
        case "1610612750":
            return "MIN"
        case "1610612740":
            return "NOP"
        case "1610612752":
            return "NYK"
        case "1610612760":
            return "OKC"
        case "1610612753":
            return "ORL"
        case "1610612755":
            return "PHI"
        case "1610612756":
            return "PHX"
        case "1610612757":
            return "POR"
        case "1610612758":
            return "SAC"
        case "1610612759":
            return "SAS"
        case "1610612761":
            return "TOR"
        case "1610612762":
            return "UTA"
        case "1610612764":
            return "WAS"
        default:
            return ""
        }
    }
    
    @IBAction func backPressed(_ sender: Any) {
        //self.performSegue(withIdentifier: "backToSelection", sender: self)
        self.dismiss(animated: true, completion: nil)
    }
    
    
    
}


