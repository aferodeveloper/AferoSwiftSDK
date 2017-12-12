//
//  ConfigureWifiViewController.swift
//  AferoLab
//
//  Created by Justin Middleton on 12/10/17.
//  Copyright © 2017 Afero, Inc. All rights reserved.
//

import UIKit

class ConfigureWifiViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
        
        tableView.estimatedSectionHeaderHeight = 31
//        tabelView.estimatedRowHeight =

    }

    // MARK: <UITableViewDatasource>
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        fatalError("implement me")
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        fatalError("implement me")
    }
    
    

    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
