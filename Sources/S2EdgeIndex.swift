//
//  S2EdgeIndex.swift
//  S2Geometry
//
//  Created by Alex Studnicka on 7/1/16.
//  Copyright © 2016 Alex Studnicka. MIT License.
//

public struct S2EdgeIndex {
	
	/*
		An iterator on data edges that may cross a query edge (a,b). Create the
		iterator, call getCandidates(), then hasNext()/next() repeatedly.
	
		The current edge in the iteration has index index(), goes between from() and to().
	*/
	public struct DataEdgeIterator: IteratorProtocol {
		
		public typealias Element = Int
		
		/// The structure containing the data edges.
		private let edgeIndex: S2EdgeIndex
		
		/// Tells whether getCandidates() obtained the candidates through brute force iteration or using the quad tree structure.
		private var isBruteForce: Bool = false
		
		/// Index of the current edge and of the edge before the last next() call.
		private var currentIndex: Int = 0
		
		/// Cache of edgeIndex.getNumEdges() so that hasNext() doesn't make an extra call
		private var numEdges: Int = 0
		
		/// All the candidates obtained by getCandidates() when we are using a quad-tree (i.e. isBruteForce = false).
		private var candidates: [Int] = []
		
		/// Index within array above. We have: currentIndex = candidates.get(currentIndexInCandidates).
		private var currentIndexInCandidates: Int = 0
		
		public init(edgeIndex: S2EdgeIndex) {
			self.edgeIndex = edgeIndex
		}
		
		/// Initializes the iterator to iterate over a set of candidates that may cross the edge (a,b).
		public mutating func getCandidates(a: S2Point, b: S2Point) {
//			edgeIndex.predictAdditionalCalls(1);
//			isBruteForce = !edgeIndex.isIndexComputed();
			if isBruteForce {
//				edgeIndex.incrementQueryCount();
				currentIndex = 0;
//				numEdges = edgeIndex.numEdges
			} else {
				candidates.removeAll()
//				edgeIndex.findCandidateCrossings(a, b, candidates);
				currentIndexInCandidates = 0
				if !candidates.isEmpty {
					currentIndex = candidates[0]
				}
			}
		}
		
		/// False if there are no more candidates; true otherwise.
		private var hasNext: Bool {
			if isBruteForce {
				return currentIndex < numEdges
			} else {
				return currentIndexInCandidates < candidates.count
			}
		}
		
		/// Iterate to the next available candidate.
		public mutating func next() -> Int? {
			guard hasNext else { return nil }
			
			if isBruteForce {
				currentIndex += 1
			} else {
				currentIndexInCandidates += 1
				if currentIndexInCandidates < candidates.count {
					currentIndex = candidates[currentIndexInCandidates]
				}
			}
			
			return currentIndex
		}
		
	}
	
}
